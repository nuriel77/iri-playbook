#!/bin/bash
# Block ToR network exit node IPs using ipset
# By Nuriel Shem-Tov @nuriel77 Jan 2018

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

function init_ubuntu(){
    dpkg -l | grep -q wget || apt-get install wget -y;
    dpkg -l | grep -q ipset || apt-get install ipset -y;
}

function init_centos(){
    rpm -q ipset >/dev/null 2>&1 || yum install -y ipset
    rpm -q wget >/dev/null 2>&1 || yum install wget -y
}

function set_iphash(){
    echo ensure ipset blacklist exits
    ipset list|grep -q '^Name: blacklist' || ipset create blacklist hash:ip hashsize 4096
    iptables -L -nv|grep -q 'match-set blacklist src' || {
        echo create drop rules for set in iptables
        iptables -I INPUT -m set --match-set blacklist src -j DROP;
        iptables -I FORWARD -m set --match-set blacklist src -j DROP;
    } && {
        echo drop rules in iptables already exist;
    }
}

function block_tor_addressess() {
    IPLIST=($(wget -qO- https://check.torproject.org/exit-addresses | grep ExitAddress | cut -d ' ' -f 2))
    for IP in "${IPLIST[@]}"; do
        ipset add blacklist $IP 2>/dev/null && echo Added new IP $IP to blacklist || /bin/true
    done
}

set_dist
# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [ "$VER" != "7" ]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    init_centos
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    init_ubuntu
else
    echo "$OS not supported"
    exit 1
fi

set_iphash
block_tor_addressess

