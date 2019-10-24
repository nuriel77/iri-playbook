#!/usr/bin/env bash
# Based on https://github.com/janeczku/haproxy-acme-validation-plugin/blob/master/cert-renewal-haproxy.sh

#### prerequisites
# - Fully qualified domain name registered and poiting to the IP of your node
# - Node installed by iri-playbook with HAProxy enabled
# - HTTPS enabled on HAProxy (will default to a self-signed certificate)
# To enable HTTPS run:
# cd /opt/iri-playbook && git pull && ansible-playbook -i inventory site.yml -v --tags=iri_ssl,loadbalancer_role -e '{"lb_bind_addresses": ["0.0.0.0"]}' -e haproxy_https=yes -e overwrite=yes

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
# Otherwise the port will try to get set from iri-playbook configuration
if [[ -z "$HAPROXY_PORT" ]]; then
    # Get the configured haproxy iri api port
    HAPROXY_PORT=$(ls /opt/iri-playbook/group_vars/all/*.yml | sort -n | xargs -d '\n' grep ^iri_api_port_remote | tail -1 | awk {'print $2'} | tr -d \'\")
    if [ $? -ne 0 ]; then
        HAPROXY_PORT=14267
    fi
fi

# Set defaults
: ${HAPROXY_CONFIG:=/etc/haproxy/haproxy.cfg}
: ${HAPROXY_TMPL:=/etc/haproxy/haproxy.cfg.tmpl}
: ${DOCKER_IMAGE:=certbot/certbot:latest}
HAPROXY_RESTART_CMD="/bin/systemctl restart haproxy"
HAPROXY_START_CMD="/bin/systemctl start haproxy"
WEBROOT="/var/lib/haproxy"

# Enable test only
[[ -n "$TEST_CERT" ]] && STAGING="--test-cert"

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
    local RC
    /bin/systemctl stop nginx
    /usr/bin/docker run \
      --rm \
      --name certbot \
      --net=host \
      -v /etc/letsencrypt:/etc/letsencrypt:Z \
      "$DOCKER_IMAGE" certonly \
      --standalone -n \
      --preferred-challenges http \
      --email "${EMAIL}" \
      -d "${DOMAIN}" \
      --agree-tos ${STAGING}
    RC=$?
    /bin/systemctl start nginx
    return $RC
}

function issueCert {
    local DOMAINS=$1
    local RC
    /bin/systemctl stop nginx
    /usr/bin/docker run \
      --rm \
      --name certbot \
      --net=host \
      -v /etc/letsencrypt:/etc/letsencrypt:Z \
      "$DOCKER_IMAGE" certonly \
      --standalone \
      --renew-by-default \
      --preferred-challenges http \
      --agree-tos ${STAGING} ${DOMAINS}
    RC=$?
    /bin/systemctl start nginx
    return $RC
}

function logger_error {
    if [ -n "${LOGFILE}" ]
    then
        echo "[error] [$(date +'%d.%m.%y - %H:%M')] ${1}" >> "${LOGFILE}"
    fi
    >&2 echo "[error] ${1}"
}

function logger_info {
    if [ -n "${LOGFILE}" ]
    then
        echo "[info] [$(date +'%d.%m.%y - %H:%M')] ${1}" >> "${LOGFILE}"
    else
        echo "[info] ${1}"
    fi
}

function add_renewal_crontab {
    echo "5 8 * * 6 root /bin/bash /usr/local/bin/certbot-haproxy.sh ${EMAIL}" | tee /etc/cron.d/cert_renew > /dev/null
}

function check_port_listen {
    lsof -Pni TCP:80|grep -q LISTEN
}

function set_nginx_redirect {
    [[ -z "$THIS_NODE" ]] && THIS_NODE=$(grep -A1 "^\[fullnode\]$" /opt/iri-playbook/inventory-multi | tail -1 | awk {'print $1'})
    VHOST="
server {
     listen 80;
     server_name _;
     return 301 http://${THIS_NODE}\$request_uri;
}
"
    logger_info "Apply nginx redirect"
    ansible -i /opt/iri-playbook/inventory-multi 'all:!'$THIS_NODE'' \
        --key-file=/home/deployer/.ssh/id_rsa \
        --become -u deployer \
        -m shell \
        -a "echo '$VHOST' >/etc/nginx/conf.d/acme_verification.conf && /bin/systemctl reload nginx"
    if [ $? -ne 0 ]; then
        # ensure removed if any error
        remove_nginx_redirect
        logger_error "Failed to apply nginx redirect"
        return 1
    fi
}

function remove_nginx_redirect {
    [[ -z "$THIS_NODE" ]] && THIS_NODE=$(grep -A1 "^\[fullnode\]$" /opt/iri-playbook/inventory-multi | tail -1 | awk {'print $1'})
    ANSIBLE_ACTION_WARNINGS=False \
      ansible -i /opt/iri-playbook/inventory-multi 'all:!'$THIS_NODE'' \
        --key-file=/home/deployer/.ssh/id_rsa \
        --become -u deployer \
        -m shell \
        -a "rm -f /etc/nginx/conf.d/acme_verification.conf && /bin/systemctl reload nginx"
}

function check_firewall {
    local IP_BIN=$1
    if [[ "$IP_BIN" == "/usr/bin/firewall-cmd" ]]
    then
        /usr/bin/firewall-cmd --list-services | grep -q -w "http" || /usr/bin/firewall-cmd --list-ports | grep -q -w "80/tcp"
    else
        /sbin/$IP_BIN -L -nv|egrep -q "ACCEPT.*tcp dpt:80$|ACCEPT.*tcp dpt:80 "
    fi
}

function enable_firewall {
    local IP_BIN=$1
    local COMMAND

    logger_info "Port 80 not open in firewall. Opening..."
    echo "Enabling $IP_BIN firewall allowed port 80"

    if [[ "$IP_BIN" == "/usr/bin/firewall-cmd" ]]
    then
        COMMAND="test -x /usr/bin/firewall-cmd && /usr/bin/firewall-cmd -q --add-service=http --permanent && /usr/bin/firewall-cmd -q --reload"
    else
        COMMAND="test -x /sbin/$IP_BIN && /sbin/$IP_BIN -I INPUT 1 -p tcp -m tcp --dport 80 -j ACCEPT"
    fi

    if [ -f /opt/iri-playbook/inventory-multi ]; then
        ansible -i /opt/iri-playbook/inventory-multi all \
            --key-file=/home/deployer/.ssh/id_rsa \
            --become -u deployer \
            -m shell \
            -a "eval $COMMAND"
    else
        eval "$COMMAND"
    fi
}

function disable_firewall {
    local IP_BIN=$1
    local COMMAND

    echo "Disabling $IP_BIN firewall port 80"

    if [[ "$IP_BIN" == "/usr/bin/firewall-cmd" ]]
    then
        COMMAND="test -x /usr/bin/firewall-cmd && /usr/bin/firewall-cmd -q --remove-service=http --permanent && /usr/bin/firewall-cmd -q --reload"
    else
        COMMAND="test -x /sbin/$IP_BIN && /sbin/$IP_BIN -D INPUT -p tcp -m tcp --dport 80 -j ACCEPT"
    fi

    if [ -f /opt/iri-playbook/inventory-multi ]; then
        ansible -i /opt/iri-playbook/inventory-multi all \
            --key-file=/home/deployer/.ssh/id_rsa \
            --become -u deployer \
            -m shell \
            -a "eval $COMMAND"
    else
        eval "$COMMAND"
    fi
}

function firewall_sequence() {
    local IP_BIN=$1
    check_firewall "$IP_BIN"
    if [ $? -ne 0 ]
    then
        CLOSE_HTTP_AFTER=true
        enable_firewall "$IP_BIN"
        if [ $? -ne 0 ]
        then
            logger_error "Error opening port 80 in iptables"
            exit 1
        fi
    else
        logger_info "Port 80 available in $ip_bin firewall."
    fi
}

function cleanup {
    if [ "$CLOSE_HTTP_AFTER" = true ]
    then
        logger_info "Disable HTTP in firewall"
        if [ -x /usr/bin/firewall-cmd ] && /usr/bin/systemctl status firewalld >/dev/null
        then
            disable_firewall "/usr/bin/firewall-cmd"
        else
            for ip_bin in iptables ip6tables; do
                if [ -x "/sbin/$ip_bin" ]; then
                    disable_firewall "$ip_bin"
                fi
            done
        fi
    fi

    if [ "$REMOVE_NGINX_REDIRECT" = true ]
    then
        logger_info "Remove nginx redirect"
        remove_nginx_redirect
    fi
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
if [ -x /usr/bin/firewall-cmd ] && /usr/bin/systemctl status firewalld >/dev/null
then
    echo "Using firewalld ..."
    firewall_sequence "/usr/bin/firewall-cmd"
else
    echo "Using iptales ..."
    for ip_bin in iptables ip6tables; do
        if [ -x "/sbin/$ip_bin" ]; then
            firewall_sequence "$ip_bin"
        fi
    done
fi

if [ -f /opt/iri-playbook/inventory-multi ]; then
    logger_info "Setting nginx redirect for other nodes"
    REMOVE_NGINX_REDIRECT=true
    set_nginx_redirect
    if [ $? -ne 0 ]
    then
        logger_error "Error creating nginx redirects"
        exit 1
    fi
fi

# Add trap for cleanup
trap cleanup EXIT INT QUIT TERM

le_cert_root="/etc/letsencrypt/live"
renewed_certs=()
exitcode=0
if [ -n "$DOMAIN" ]
then
    newCert
    RC=$?
    if [ $RC -ne 0 ]
    then
        logger_error "Error requesting a new certificate for $DOMAIN"
        exitcode=1
    fi
    renewed_certs+=("$DOMAIN")
    DOMAIN_DIR=$(find "${le_cert_root}" -type d -name "${DOMAIN}*" -print -quit)
else
    if [ ! -d ${le_cert_root} ]; then
        logger_error "${le_cert_root} does not exist!"
        exit 1
    fi

    while IFS= read -r -d '' cert; do
        DOMAIN_DIR=$(dirname "${cert}")
        if ! openssl x509 -noout -checkend $((4*7*86400)) -in "${cert}"; then
            subject="$(openssl x509 -noout -subject -in "${cert}" | grep -o -E 'CN ?= ?[^ ,]+' | tr -d 'CN= ?')"
            subjectaltnames="$(openssl x509 -noout -text -in "${cert}" | sed -n '/X509v3 Subject Alternative Name/{n;p}' | sed 's/\s//g' | tr -d 'DNS:' | sed 's/,/ /g')"
            echo "Certificate's CN/subject: '$subject'"
            echo "Certificates subjectAltNames: '$subjectaltnames'"
            if [ "$subject" != "" ]
            then
                domains="-d ${subject}"
            fi
            for name in ${subjectaltnames}; do
                if [ "${name}" != "${subject}" ]; then
                    domains="${domains} -d ${name}"
                fi
            done
            echo "IssueCert ${domains}"
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
            # If all certificates seem okay, check whether the haproxy.pem
            # has already been updated, else add the name to be processed
            # so that haproxy.pem gets updated.
            HAPROXY_CERT=$(find "${DOMAIN_DIR}" -type f -name haproxy.pem)
            if [ $? -eq 0 ] && [[ "${HAPROXY_CERT}x" != "x" ]]; then
                echo $cert
                if ! openssl x509 -noout -checkend $((4*7*86400)) -in "${HAPROXY_CERT}"; then
                    subject="$(openssl x509 -noout -subject -in "${cert}" | grep -o -E 'CN ?= ?[^ ,]+' | tr -d 'CN= ?')"
                    renewed_certs+=("$subject")
                    logger_info "${HAPROXY_CERT} older than ${cert}, mark for update from certificates."
                fi
            fi
            logger_info "none of the certificates requires renewal"
        fi
    done < <(find "${le_cert_root}" -name cert.pem -print0)
fi

# At this stage, the above has exited 0
# If any domains in the renewed_certs array
# the following code will create/refresh the haproxy.pem
if [[ $exitcode -eq 0 ]]; then
    # create haproxy.pem file(s)
    for domain in ${renewed_certs[@]}; do
        full_path=$(find "${le_cert_root}" -type d -name "${domain}*" -print -quit)
        cat "${full_path}/fullchain.pem" "${full_path}/privkey.pem" | tee "${full_path}/haproxy.pem" >/dev/null
        if [ $? -ne 0 ]; then
            logger_error "failed to create haproxy.pem file!"
            exit 1
        fi
        chmod 400 "${full_path}/haproxy.pem"

        # Operate on multi node configuration
        if [ -f /opt/iri-playbook/inventory-multi ]; then

            # Create directory for letsencrypt certs
            ansible -i /opt/iri-playbook/inventory-multi all \
                --key-file=/home/deployer/.ssh/id_rsa \
                --become -u deployer \
                -m shell \
                -a "mkdir -p ${full_path}"

            # Cooy generated haproxy.pem certificate
            ansible -i /opt/iri-playbook/inventory-multi all \
                --key-file=/home/deployer/.ssh/id_rsa \
                --become -u deployer \
                -m copy \
                -a "src=${full_path}/haproxy.pem dest=${full_path}/haproxy.pem mode=0400"
        fi

    done

    grep -q "$DOMAIN_DIR/haproxy.pem" /etc/haproxy/haproxy.cfg
    HAPROXY_RESTART=$?

    if [[ $HAPROXY_RESTART -eq 1 ]]; then
        # Match certificate name for haproxy
        sed -i "\|^[ \t]*bind[ \t]*.*:${HAPROXY_PORT}|s|^\(.* \)crt[ \t]*.*|\1crt ${DOMAIN_DIR}/haproxy.pem|g" "$HAPROXY_CONFIG"
    fi

    # Configure if haproxy template file exists
    if [[ -f "$HAPROXY_TMPL" ]]; then
        # Search for any lines beginning with bind to any interface with HAPROXY defined port.
        # Replace the existing certificate with the new certificate for the requested domain.
        sed -i "\|^[ \t]*bind[ \t]*.*:${HAPROXY_PORT}|s|^\(.* \)crt[ \t]*.*|\1crt ${DOMAIN_DIR}/haproxy.pem|g" "$HAPROXY_CONFIG"
    fi

    # Apply haproxy.cfg configuration to multi node setup
    if [ -f /opt/iri-playbook/inventory-multi ]; then
        ansible -i /opt/iri-playbook/inventory-multi all \
            --key-file=/home/deployer/.ssh/id_rsa \
            --become -u deployer \
            -m shell \
            -a "grep -q \"$DOMAIN_DIR/haproxy.pem\" \"$HAPROXY_CONFIG\" || sed -i \"\|^[ \t]*bind[ \t]*.*:${HAPROXY_PORT}|s|^\(.* \)crt[ \t]*.*|\1crt ${DOMAIN_DIR}/haproxy.pem|g\" \"$HAPROXY_CONFIG\" \"$HAPROXY_TMPL\" && systemctl reload haproxy && systemctl restart consul-template || /bin/true"
    fi

    # restart haproxy
    if [ "${#renewed_certs[@]}" -gt 0 ] || [[ $HAPROXY_RESTART -eq 1 ]]; then
        systemctl status haproxy >/dev/null
        RC_A=$?
        if [[ $RC_A -eq 3 ]]; then
            $HAPROXY_START_CMD
            RC_B=$?
            systemctl status consul-template >/dev/null 2>&1 && systemctl restart consul-template
            RC_C=$?
        elif [[ $RC_A -eq 0 ]]; then
            $HAPROXY_RESTART_CMD
            RC_B=$?
            systemctl status consul-template >/dev/null 2>&1 && systemctl restart consul-template
            RC_C=$?
        fi

        if [[ $RC_B -ne 0 ]]; then
            logger_error "failed to restart haproxy!"
        fi

        if [[ $RC_C -ne 0 ]] && [[ $RC_C -ne 4 ]]; then
            logger_error "failed to restart consul-template!"
        fi
    fi
fi

add_renewal_crontab
