#!/bin/bash

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
#
# If you only provide argument 1 to the script, any existing certificate
# will be renewed.
# If you provide both email and domain, a new certificate will be installed.

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
HAPROXY_PORT=${HAPROXY_PORT:-14267}
HAPROXY_CONFIG=${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}
HAPROXY_RELOAD_CMD="systemctl reload haproxy"
WEBROOT="/var/lib/haproxy"

# Enable to redirect output to logfile (for silent cron jobs)
LOGFILE="/var/log/certrenewal.log"

######################
## utility function ##
######################

function get_email() {
    echo -n "Enter your email address to register as an account with Let's Encrypt and click [ENTER]: "
    read EMAIL
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

function set_dist() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        echo "Unsupported OS."
        exit 1
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        echo "Old OS version. Minimum required is 7."
        exit 1
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

function newCert {
    $LE_CLIENT certonly --standalone --email ${EMAIL} -d ${DOMAIN} -n --preferred-challenges http --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --agree-tos
    return $?
}

function issueCert {
    echo $LE_CLIENT certonly --standalone --renew-by-default --preferred-challenges http --agree-tos --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --email ${EMAIL} -d "$1"
        $LE_CLIENT certonly --standalone --renew-by-default --preferred-challenges http --agree-tos --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --email ${EMAIL} $1
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

# Set OS distribution
set_dist

if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [ -n "$DOMAIN" ]
    then
        logger_info "Start installation of certbot ..."
        yum install epel-release -y
        yum install certbot -y
    fi
    LE_CLIENT="/bin/certbot"
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [ -n "$DOMAIN" ]
    then
        logger_info "Start installation of certbot ..."
        add-apt-repository ppa:certbot/certbot -y
        apt-get update -y
        apt-get install certbot -y
    fi
    LE_CLIENT="/usr/bin/certbot"
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
        exit 1
    fi
    renewed_certs+=("$DOMAIN")
else
    if [ ! -d ${le_cert_root} ]; then
        logger_error "${le_cert_root} does not exist!"
        exit 1
    fi

    exitcode=0
    while IFS= read -r -d '' cert; do
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

# create haproxy.pem file(s)
for domain in ${renewed_certs[@]}; do
    cat ${le_cert_root}/${domain}/fullchain.pem ${le_cert_root}/${domain}/privkey.pem | tee ${le_cert_root}/${domain}/haproxy.pem >/dev/null
    if [ $? -ne 0 ]; then
        logger_error "failed to create haproxy.pem file!"
        exit 1
    fi
    chmod 400 ${le_cert_root}/${domain}/haproxy.pem
done

if [ -z "$DOMAIN" ]
then
    DOMAIN=${subjectaltnames}
fi
# Match certificate name for haproxy
sed -i "s|bind 0.0.0.0:${HAPROXY_PORT} ssl crt .*|bind 0.0.0.0:${HAPROXY_PORT} ssl crt ${le_cert_root}/${DOMAIN}/haproxy.pem|" $HAPROXY_CONFIG

# restart haproxy
if [ "${#renewed_certs[@]}" -gt 0 ]; then
    $HAPROXY_RELOAD_CMD
    if [ $? -ne 0 ]; then
        logger_error "failed to reload haproxy!"
        exit 1
    fi
fi

add_renewal_crontab
