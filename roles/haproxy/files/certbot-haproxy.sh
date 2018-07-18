#!/bin/bash
# Based on https://github.com/janeczku/haproxy-acme-validation-plugin/blob/master/cert-renewal-haproxy.sh

#### prerequisites
# - Fully qualified domain name registered and poiting to the IP of your node
# - Node installed by iri-playbook with HAProxy enabled
# - HTTPS enabled on HAProxy (will default to a self-signed certificate)
# To enable HTTPS run:
# cd /opt/iri-playbook && git pull && ansible-playbook -i inventory site.yml -v --tags=iri_ssl,loadbalancer_role -e lb_bind_address=0.0.0.0 -e haproxy_https=yes -e overwrite=yes

# This script will automate certificate creation and renewal for let's encrypt and haproxy
# - checks all certificates under /etc/letsencrypt/live and renews
#   those about about to expire in less than 4 weeks
# - creates haproxy.pem files in /etc/letsencrypt/live/domain.tld/
# - Ensures firewall allows connections
# - Update haproxy
# - Install renewal crontab

#### USAGE
# The script takes one or two arguments:
# - argument 1: email address (becomes your acme/letsencrypt account)
# - argument 2: domain name to issue a new certificate for
# If you only specify the email address, certificates will be renewed.
# If you specify both email and domain, a new certificate will be requested.

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as user root"
   echo "Please change to root using: 'sudo su -' and re-run the script"
   exit 1
fi

###################
## configuration ##
###################

# To override 14267 you can specify HAPROXY_PORT environment variable
# before running this script (or set on the same command-line)
: ${HAPROXY_PORT:=14267}
: ${HAPROXY_CONFIG:=/etc/haproxy/haproxy.cfg}
: ${DOCKER_IMAGE:=nuriel77/certbot:latest}
HAPROXY_RESTART_CMD="/bin/systemctl restart haproxy"
HAPROXY_START_CMD="/bin/systemctl start haproxy"
WEBROOT="/var/lib/haproxy"

# Enable to redirect output to logfile (for silent cron jobs)
LOGFILE="/var/log/certrenewal.log"

######################
## utility function ##
######################

function get_email() {
    echo -n "Enter your email address to register as an account with Let's Encrypt and click [ENTER]: "
    read EMAIL
    if [[ "$EMAIL" == "" ]]; then
        echo "You must provide an email address"
        get_email
        return
    fi
    echo -n "Please repeat and click [ENTER]: "
    read EMAIL_CHECK
    if [ "$EMAIL" != "$EMAIL_CHECK" ]
    then
        echo
        echo "Email addresses do not match!"
        get_email
    fi
}

function get_domain() {
    echo -n "Enter the domain name that points to this server and click [ENTER]: "
    read DOMAIN
    echo -n "Please repeat and click [ENTER]: "
    read DOMAIN_CHECK
    if [ "$DOMAIN" != "$DOMAIN_CHECK" ]
    then
        echo
        echo "Domain names do not match!"
        get_domain
    fi
}

function newCert {
    /usr/bin/docker run \
      --rm \
      --name certbot \
      -v /var/run/docker.sock:/var/run/docker.sock:Z \
      -v /etc/letsencrypt:/etc/letsencrypt:Z \
      "$DOCKER_IMAGE" certonly \
      --standalone -n \
      --preferred-challenges http \
      --email "${EMAIL}" \
      -d "${DOMAIN}" \
      --agree-tos \
      --pre-hook "docker stop nginx" \
      --post-hook "docker start nginx"
    return $?
}

function issueCert {
    /usr/bin/docker run \
      --rm \
      --name certbot \
      -v /var/run/docker.sock:/var/run/docker.sock:Z \
      -v /etc/letsencrypt:/etc/letsencrypt:Z \
      "$DOCKER_IMAGE" certonly \
      --standalone \
      --renew-by-default \
      --preferred-challenges http \
      --agree-tos \
      --pre-hook "docker stop nginx" \
      --post-hook "docker start nginx"
    return $?
}

function logger_error {
    if [ -n "${LOGFILE}" ]
    then
        echo "[error] [$(date +'%d.%m.%y - %H:%M')] ${1}" >> ${LOGFILE}
    fi
    >&2 echo "[error] ${1}"
}

function logger_info {
    if [ -n "${LOGFILE}" ]
    then
        echo "[info] [$(date +'%d.%m.%y - %H:%M')] ${1}" >> ${LOGFILE}
    else
        echo "[info] ${1}"
    fi
}

function add_renewal_crontab {
    echo "5 8 * * 6 root /bin/bash /usr/local/bin/certbot-haproxy.sh ${EMAIL}" | tee /etc/cron.d/cert_renew > /dev/null
}

function check_firewall {
    iptables -L -nv|grep -q "ACCEPT.*tcp dpt:80"
}

function check_port_listen {
    lsof -Pni TCP:80|grep -q LISTEN
}

function enable_firewall {
    /sbin/iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
}

function disable_firewall {
    /sbin/iptables -D INPUT -p tcp -m tcp --dport 80 -j ACCEPT
}

##################
## main routine ##
##################

if [ -z "$1" ]
then
    clear
    get_email
    echo
    get_domain
else
    EMAIL=$1
    DOMAIN=$2
fi

if [ ! -f "$HAPROXY_CONFIG" ]
then
    logger_error "Cannot find haproxy config at '$HAPROXY_CONFIG'"
    exit 1
fi

# Check firewall open for 80/tcp
check_firewall
if [ $? -ne 0 ]
then
    logger_info "Port 80 not open in firewall. Opening..."
    CLOSE_HTTP_AFTER=1
    enable_firewall
    if [ $? -ne 0 ]
    then
        logger_error "Error opening port 80 in iptables"
        exit 1
    fi
else
    logger_info "Port 80 available in firewall."
fi

le_cert_root="/etc/letsencrypt/live"
renewed_certs=()
exitcode=0
if [ -n "$DOMAIN" ]
then
    newCert
    RC=$?
    if [ "$CLOSE_HTTP_AFTER" == "1" ]
    then
        disable_firewall
    fi
    if [ $RC -ne 0 ]
    then
        logger_error "Error requesting a new certificate for $DOMAIN"
        exitcode=1
    fi
    renewed_certs+=("$DOMAIN")
    DOMAIN_DIR="${le_cert_root}/${DOMAIN}"
else
    if [ ! -d ${le_cert_root} ]; then
        logger_error "${le_cert_root} does not exist!"
        exit 1
    fi

    while IFS= read -r -d '' cert; do
        DOMAIN_DIR=$(dirname "${cert}")
        if ! openssl x509 -noout -checkend $((4*7*86400)) -in "${cert}"; then
            subject="$(openssl x509 -noout -subject -in "${cert}" | grep -o -E 'CN=[^ ,]+' | tr -d 'CN=')"
            subjectaltnames="$(openssl x509 -noout -text -in "${cert}" | sed -n '/X509v3 Subject Alternative Name/{n;p}' | sed 's/\s//g' | tr -d 'DNS:' | sed 's/,/ /g')"
            if [ "$subject" != "" ]
            then
                domains="-d ${subject}"
            fi
            for name in ${subjectaltnames}; do
                if [ "${name}" != "${subject}" ]; then
                    domains="${domains} -d ${name}"
                fi
            done
            issueCert "${domains}"
            if [ $? -ne 0 ]
            then
                logger_error "failed to renew certificate! check /var/log/letsencrypt/letsencrypt.log!"
                exitcode=1
            else
                renewed_certs+=("$subject")
                logger_info "renewed certificate for ${subject}"
            fi
        else
            logger_info "none of the certificates requires renewal"
        fi
    done < <(find /etc/letsencrypt/live -name cert.pem -print0)
fi

if [[ $exitcode -eq 0 ]]; then
    # create haproxy.pem file(s)
    for domain in ${renewed_certs[@]}; do
        cat ${le_cert_root}/${domain}/fullchain.pem ${le_cert_root}/${domain}/privkey.pem | tee ${le_cert_root}/${domain}/haproxy.pem >/dev/null
        if [ $? -ne 0 ]; then
            logger_error "failed to create haproxy.pem file!"
            exit 1
        fi
        chmod 400 ${le_cert_root}/${domain}/haproxy.pem
    done

    grep -q $DOMAIN_DIR/haproxy.pem /etc/haproxy/haproxy.cfg
    HAPROXY_RESTART=$?

    if [[ $HAPROXY_RESTART -eq 1 ]]; then
        # Match certificate name for haproxy
        sed -i "s|bind 0.0.0.0:${HAPROXY_PORT} ssl crt .*|bind 0.0.0.0:${HAPROXY_PORT} ssl crt ${DOMAIN_DIR}/haproxy.pem|" $HAPROXY_CONFIG
    fi

    # restart haproxy
    if [ "${#renewed_certs[@]}" -gt 0 ] || [[ $HAPROXY_RESTART -eq 1 ]]; then
        systemctl status haproxy >/dev/null
        if [[ $? -eq 3 ]]; then
            $HAPROXY_START_CMD
            RC=$?
	elif [[ $? -eq 0 ]]; then
            $HAPROXY_RESTART_CMD
            RC=$?
        fi

        if [[ $RC -ne 0 ]]; then
            logger_error "failed to restart haproxy!"
        fi
    fi
fi

add_renewal_crontab
