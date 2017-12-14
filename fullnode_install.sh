#!/usr/bin/env bash
# This script will auto-detect the OS and Version
# It will update system packages and install Ansible and git
# Then it will clone the iri-playbook and run it.

# Iri playbook: https://github.com/nuriel77/iri-playbook
# By Nuriel Shem-Tov (https://github.com/nuriel77), December 2017

set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please change to root: 'sudo su -' and re-run"
   exit 1
fi

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

function init_centos(){
    echo "Updating system packages..."
    yum update -y

    echo "Install yum utils..."
    yum install -y yum-utils

    if $(needs-restarting -r 2>&1 | grep -q "Reboot is required"); then
        inform_reboot
        exit 0
    fi

    echo "Installing Ansible, net-tools and git..."
    yum install ansible git net-tools -y

}

function init_ubuntu(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        inform_reboot
        exit 0
    fi

    echo "Installing Ansible, net-tools and git..."
    apt-get install software-properties-common -y
    apt-add-repository ppa:ansible/ansible -y
    apt-get update -y
    apt-get install ansible git  net-tools -y
}

function inform_reboot() {
cat <<EOF
It is required to reboot the machine because of upgraded system packages.

*** Please reboot this machine and re-run the script ***

To reboot run: 'shutdown -r now'
-> Remember to re-run the script inside a "screen" session: 'screen -S iota'.
EOF
}

function get_password() {
    unset PASSWORD
    unset CHARCOUNT
    stty -echo

    CHARCOUNT=0
    while IFS= read -p "$PROMPT" -r -e -s -n 1 CHAR; do
        # Enter - accept password
        if [[ $CHAR == $'\0' ]]; then
            break
        fi
        # Backspace (BUG: Doesn't work, no big deal)
        # If user had a mistake he will have to re-enter
        if [[ $CHAR == $'\177' ]] ; then
            if [ $CHARCOUNT -gt 0 ] ; then
                CHARCOUNT=$((CHARCOUNT-1))
                PROMPT=$'\b \b'
                PASSWORD="${PASSWORD%?}"
            else
                PROMPT=''
            fi
        else
            CHARCOUNT=$((CHARCOUNT+1))
            PROMPT='*'
            PASSWORD+="$CHAR"
        fi
    done

    stty echo
    echo $PASSWORD
}

function set_password() {
    echo "--------------"
    echo "Please enter the password with which you will connect to IOTA Peer Mananger"
    echo "Use a stong password!!! Not 'hello123' or 'iota8181', you get the point ;)"
    echo -n "Password: "
    PASSWORD_A=$(get_password)
    echo
    echo -n "Please repeat: "
    PASSWORD_B=$(get_password)
    if [ "$PASSWORD_A" != "$PASSWORD_B" ]; then
        echo -e "\n\nPasswords do not match!\n"
        set_password
    fi
    sed -i "s/^iotapm_nginx_password:.*$/iotapm_nginx_password: '$PASSWORD_A'/" group_vars/all/iotapm.yml
}

# Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [ "$VER" != "7" ]; then
        echo "$OS version $VER not supported"
        exit 1
    fi
    init_centos
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^16 ]]; then
        echo "$OS version $VER not supported"
        exit 1
    fi
    init_ubuntu
else
    echo "$OS not supported"
    exit 1
fi

echo "Verifying Ansible version..."
ANSIBLE_VERSION=$(ansible --version|head -1|awk {'print $2'}|cut -d. -f1-2)
if (( $(awk 'BEGIN {print ("'2.4'" > "'$ANSIBLE_VERSION'")}') )); then
    echo "Error: Ansible minimum version 2.4 required."
    echo "Please remove Ansible: (yum remove ansible -y for CentOS, or apt-get remove -y ansible for Ubuntu)."
    echo
    echo "Then refer to the documentation on how to get latest Ansible installed:"
    echo "http://docs.ansible.com/ansible/latest/intro_installation.html#latest-release-via-yum"
    exit 1
fi

echo "Git cloning iri-playbook repository..."
cd /opt

if [ -d iri-playbook ]; then
    rm -rf iri-playbook
fi

git clone https://github.com/nuriel77/iri-playbook.git
cd iri-playbook


set_password
echo -e "\nRunning playbook..."

ansible-playbook -i inventory -v site.yml -e "memory_autoset=true"

PRIMARY_IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

cat <<EOF
Installation done!


You should be able to connect to IOTA Peer Manager pointing your browser to:

http://${PRIMARY_IP}:8811


You can reach the monitoring (grafana) graphs at:

http://${PRIMARY_IP}:5555


Note that your IP might be different as this one has been auto-detected in best-effort.
You can use the username 'iotapm' and the password you entered during the installation.


Please refer to the tutorial for post-installation information:
http://iri-playbook.readthedocs.io/en/docs/post-installation.html
EOF
