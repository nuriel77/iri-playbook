#!/bin/bash
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
HAPROXY_PORT=${HAPROXY_PORT:-14267}
HAPROXY_CONFIG=${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}
HAPROXY_RESTART_CMD="systemctl restart haproxy"
HAPROXY_START_CMD="systemctl start haproxy"
WEBROOT="/var/lib/haproxy"

# Enable test only
[[ -n "$TEST_CERT" ]] && TEST_CERT="--test-cert"

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
    $LE_CLIENT certonly \
               --standalone \
               --email "${EMAIL}" \
               -d "${DOMAIN}" \
               -n \
               --preferred-challenges http \
               --pre-hook "systemctl stop nginx" \
               --post-hook "systemctl start nginx" \
               --agree-tos ${TEST_CERT}
}

function issueCert {
    $LE_CLIENT certonly \
               --standalone \
               --renew-by-default \
               --preferred-challenges http \
               --agree-tos \
               --pre-hook "systemctl stop nginx" \
               --post-hook "systemctl start nginx" \
               --email "${EMAIL}" "$1" ${TEST_CERT}
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

function check_firewall {
    local IP_BIN=$1
    /sbin/$IP_BIN -L -nv|grep -q "ACCEPT.*tcp dpt:80"
}

function enable_firewall {
    local IP_BIN=$1
    echo "Enabling $IP_BIN firewall allowed port 80"
    /sbin/$IP_BIN -I INPUT 1 -p tcp -m tcp --dport 80 -j ACCEPT
}

function disable_firewall {
    local IP_BIN=$1
    echo "Disabling $IP_BIN firewall port 80"
    /sbin/$IP_BIN -D INPUT -p tcp -m tcp --dport 80 -j ACCEPT
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
        # Temporary fix for pyOpenSSL error on CentOS
        # src: https://www.getpagespeed.com/troubleshooting/fix-importerror-pyopenssl-module-missing-required-functionality-try-upgrading-to-v0-14-or-newer
        echo y | pip uninstall requests --disable-pip-version-check -q
        echo y | pip uninstall six --disable-pip-version-check -q
        echo y | pip uninstall urllib3 --disable-pip-version-check -q
        yum -y reinstall \
            python-requests \
            python-six \
            python-urllib3
    fi
    LE_CLIENT="/bin/certbot"
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [ -n "$DOMAIN" ]
    then
        logger_info "Start installation of certbot ..."
        apt-get update -y
        apt-get install software-properties-common -y
        add-apt-repository ppa:certbot/certbot -y
        apt-get update -y
        apt-get install certbot -y
    fi
    LE_CLIENT="/usr/bin/certbot"
fi

# Check firewall open for 80/tcp
for ip_bin in iptables ip6tables; do
    #echo "PROCESS $ip_bin"
    if [ -x "/sbin/$ip_bin" ]; then
        check_firewall "$ip_bin"
        if [ $? -ne 0 ]
        then
            logger_info "Port 80 not open in firewall. Opening..."
            CLOSE_HTTP_AFTER=1
            enable_firewall "$ip_bin"
            if [ $? -ne 0 ]
            then
                logger_error "Error opening port 80 in iptables"
                exit 1
            fi
        else
            logger_info "Port 80 available in $ip_bin firewall."
        fi
    fi
done

le_cert_root="/etc/letsencrypt/live"
renewed_certs=()
exitcode=0
if [ -n "$DOMAIN" ]
then
    newCert
    RC=$?
    if [ "$CLOSE_HTTP_AFTER" == "1" ]
    then
        for ip_bin in iptables ip6tables; do
            if [ -x "/sbin/$ip_bin" ]; then
                disable_firewall "$ip_bin"
            fi
        done
    fi
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
    done < <(find /etc/letsencrypt/live -name cert.pem -print0)
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
    done

    grep -q $DOMAIN_DIR/haproxy.pem /etc/haproxy/haproxy.cfg
    HAPROXY_RESTART=$?

    if [[ $HAPROXY_RESTART -eq 1 ]]; then
        # Match certificate name for haproxy
        # Search for any lines beginning with bind to any interface with HAPROXY defined port.
        # Replace the existing certificate with the new certificate for the requested domain.
        sed -i "\|^[ \t]*bind[ \t]*.*:${HAPROXY_PORT}|s|^\(.* \)crt[ \t]*.*|\1crt ${DOMAIN_DIR}/haproxy.pem|g" "$HAPROXY_CONFIG"
    fi

    # restart haproxy
    if [ "${#renewed_certs[@]}" -gt 0 ] || [[ $HAPROXY_RESTART -eq 1 ]]; then
        systemctl status haproxy >/dev/null
        RC_A=$?
        if [[ $RC_A -eq 3 ]]; then
            $HAPROXY_START_CMD
            RC_B=$?
    elif [[ $RC_A -eq 0 ]]; then
            $HAPROXY_RESTART_CMD
            RC_B=$?
        fi

        if [[ $RC_B -ne 0 ]]; then
            logger_error "failed to restart haproxy!"
        fi
    fi
fi

add_renewal_crontab
