#!/usr/bin/env bash
# This script will auto-detect the OS and Version
# It will update system packages and install Ansible and git
# Then it will clone the iri-playbook and run it.

# Iri playbook: https://github.com/nuriel77/iri-playbook
# By Nuriel Shem-Tov (https://github.com/nuriel77), December 2017
# Copyright (c) 2017 Nuriel Shem-Tov

set -o pipefail
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as user root"
   echo "Please change to root using: 'sudo su -' and re-run the script"
   exit 1
fi

export NEWT_COLORS='
window=,
'

declare -g INSTALL_OPTIONS

clear
cat <<'EOF'


                                                                   .odNMMmy:
                                                                   /MMMMMMMMMy
                                                                  `NMMMMMMMMMM:
                                                                   mMMMMMMMMMM-
                                `::-                               -dMMMMMMMN/
                    `+sys/`    sNMMMm/   /ydho`                      :oyhhs/`
                   :NMMMMMm-  -MMMMMMm  :MMMMMy  .+o/`
                   hMMMMMMMs   sNMMMm:  `dMMMN/ .NMMMm
                   -mMMMMMd.    `-:-`     .:-`  `hMMNs -syo`          .odNNmy/        `.
                    `:oso:`                       `.`  mMMM+         -NMMMMMMMy    :yNNNNh/
                       `--.      :ydmh/    `:/:`       -os+`/s+`     sMMMMMMMMM`  +MMMMMMMMs
                     .hNNNNd/   /MMMMMM+  :mMMMm-   ``     -MMM+     -NMMMMMMMy   hMMMMMMMMN
            ``       mMMMMMMM-  :MMMMMM/  oMMMMM/ .hNNd:    -/:`      .odmmdy/`   :NMMMMMMN+
         -sdmmmh/    dMMMMMMN.   -shhs:   `/yhy/  /MMMMs `--`           ````       .ohddhs-
        :NMMMMMMMy   `odmNmy-                      /ss+``dNNm.         .-.`           ``
        yMMMMMMMMM`    ``.`                             `hNNh.       /dNNNms`      `-:-`
        :NMMMMMMMs          .--.      /yddy:    .::-`    `..`       /MMMMMMMh    `smNNNms`
         .ohdmdy:         -hmNNmh:   +MMMMMM/  /mMMNd.   ``         :MMMMMMMy    oMMMMMMMs   `-::.
            ```  ``      `NMMMMMMN.  +MMMMMN:  yMMMMM- -hmmh-        /hmNNdo`    +MMMMMMM+  +mNMNNh-
              -sdmmdy:   `mMMMMMMN`   :yhhs-   `+hhy:  oMMMMo          ...`       /hmmmh/  :MMMMMMMm
             /NMMMMMMNo   .sdmmmy-                     `+yy/`     -+ss+.            `.`    .NMMMMMMh
             dMMMMMMMMN     `..`                                 /NMMMMm-      :shyo.       -sdmmh+`
     `       /NMMMMMMMo                 .-.                      oMMMMMM/     sMMMMMm.        ```
 `/ydddho-    -sdmmdy:                `hNNms                     `odmmd+      yMMMMMN-   -shhs:
-mMMMMMMMNo     ````           `--.   `mMMMm                 `-//- `..        `odddy:   :NMMMMN/
mMMMMMMMMMM:            .//.   yNMN/   .+o/.                `dMMMNo       ./o+-  ``     /MMMMMM+
mMMMMMMMMMM:            dMMd   ommd:     -+o/.              .NMMMMy      -mMMMN+         /hddh/
:mMMMMMMMNs             -oo-    .:.     +NMMMm-         .//- -shy+`      -NMMMMo    `/oo:`  `
 `+ydmmdo-            `ohy/    smmdo    oMMMMN:        /NMMN+       `:++- -oso:    `dMMMMh
     ``               /MMMm   `NMMMN`    :oso-         :mMMN/       oMMMM/         `mMMMMh
                       :o+-    -oyo-         -+oo:`     .::.   -oo: /mNNm-     -+o/``/ss/`
                      `:oo:      .:/-`      oMMMMMh`          `NMMM- `--`     :MMMMy
                      oMMMM/    :mMMMm-     mMMMMMM.           +hho`     .+s+`.dNNm+
                      :mNNd-    oMMMMM/     -hmNNd/                 -o+. hMMMo  .-`
                       `..``    `/yhy/        `.`  `:oss+.          mMMh -shs.
                        :ydds.       .://.        `hMMMMMN+         -+/.
                       .MMMMMm      +NMMMMy       /MMMMMMMm
                        yNNNN+      mMMMMMM-      `dMMMMMN+    ````
                         .--` ``    :dNNNmo         :oss+.   -ydNNmh/
                            /hmmh+`   .--`  ./++:`          /MMMMMMMMy
                           :MMMMMMs        yMMMMMm/         hMMMMMMMMM      `-::-`
                           -NMMMMM+       /MMMMMMMN         :NMMMMMMMo    -yNMMMMMh:
                            .oyys-   ``   `mMMMMMMs          .ohmmds-    -NMMMMMMMMM+
                                  `+dNNmy- `+yhhs:   `ohmmds-            sMMMMMMMMMMd
                                  hMMMMMMM-         -NMMMMMMMs           :MMMMMMMMMMo
                                  dMMMMMMM:         yMMMMMMMMM`           :dMMMMMMm+
                                  .hMMMMm+          :MMMMMMMMy              .:++/.
                                    `--.             -ymMMNh/

EOF


cat <<EOF
Welcome to IOTA FullNode Installer!
1. By pressing 'y' you agree to install the IRI fullnode on your system.
2. By pressing 'y' you aknowledge that this installer requires a CLEAN operating system
   and may otherwise !!!BREAK!!! existing software on your server (visit link below).
3. You read and agree to http://iri-playbook.readthedocs.io/en/master/disclaimer.html
4. This installation ensures firewall is enabled.
5. If you already have a configured server, re-running this script might overwrite previous configuration.

EOF

read -p "Do you wish to proceed? [y/N] " yn
if echo "$yn" | grep -v -iq "^y"; then
    echo Cancelled
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

    set +e
    set +o pipefail
    if $(needs-restarting -r 2>&1 | grep -q "Reboot is required"); then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi
    set -o pipefail
    set -e

    echo "Installing Ansible and git..."
    yum install ansible git expect-devel cracklib newt -y
}

function init_ubuntu(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    apt-get install software-properties-common -y
    apt-add-repository ppa:ansible/ansible -y
    apt-get update -y
    apt-get install ansible git expect-dev tcl libcrack2 cracklib-runtime whiptail -y
}

function inform_reboot() {
cat <<EOF


======================== PLEASE REBOOT AND RE-RUN THIS SCRIPT =========================

Some system packages have been updated which require a reboot
and allow the node installer to proceed with the installation.

*** Please reboot this machine and re-run this script ***


>>> To reboot run: 'shutdown -r now', when back online:
bash <(curl -s https://raw.githubusercontent.com/nuriel77/iri-playbook/master/fullnode_install.sh)

!! Remember to re-run this script as root !!


EOF
}

function set_admin_password_a() {
    whiptail --title "Admin Password" \
             --passwordbox "Please enter the password with which you will connect to services (IOTA Peer manager, Grafana, etc). Use a stong password!!! Not 'hello123' or 'iota8181', you get the point ;). Only valid ASCII characters are allowed." \
             10 78 3>&1 1>&2 2>&3

    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi
}

function set_admin_password_b() {
    whiptail --passwordbox "please repeat" 8 78 --title "Admin Password" 3>&1 1>&2 2>&3
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi
}

function get_admin_password() {

    # Get first password and validate ascii characters only
    local PASSWORD_A=$(set_admin_password_a)
    if [[ "$PASSWORD_A" == "Installation cancelled" ]]; then
        echo "$PASSWORD_A"
        exit 1
    fi

    local LC_CTYPE=C
    case "${PASSWORD_A}" in
        *[![:cntrl:][:print:]]*)
            whiptail --title "Invalid characters!!" \
                     --msgbox "Only ASCII characters are allowed:\n\n!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~" \
                     12 78
            get_admin_password
            return
            ;;
    esac

    # Get password again and check passwords match
    local PASSWORD_B=$(set_admin_password_b)
    if [[ "$PASSWORD_B" == "Installation cancelled" ]]; then
        echo "$PASSWORD_B"
        exit 1
    fi
    if [ "$PASSWORD_A" != "$PASSWORD_B" ]; then
        whiptail --title "Passwords Mismatch!" \
                 --msgbox "Passwords do not match, please try again." \
                 8 78
        get_admin_password
    fi

    PASSWD_CHECK=$(echo -n "$PASSWORD_A" | cracklib-check)
    if [[ $(echo "$PASSWD_CHECK" | awk {'print $2'}) != "OK" ]]; then
        whiptail --title "Weak Password!" \
                 --msgbox "Please choose a better password:$(echo ${PASSWD_CHECK}|cut -d: -f2-)" \
                 8 78
        get_admin_password
    fi

    # Ensure we escape single quotes (using single quotes) because we need to
    # encapsulate the password with single quotes for the Ansible variable file
    PASSWORD_A=$(echo "${PASSWORD_A}" | sed "s/'/''/g")
    echo "iotapm_nginx_password: '${PASSWORD_A}'" > group_vars/all/z-override-iotapm.yml
}

# Installation selection menu
function set_selections()
{
    local RC RESULTS RESULTS_ARRAY CHOICE SKIP_TAGS
    SKIP_TAGS="--skip-tags=_"

    RESULTS=$(whiptail --title "Installation Options" --checklist \
        --cancel-button "Exit" \
        "\nPlease choose additional installation options.\n(Its perfectly okay to leave this as is).\n\
For more information about these options visit this link:\n
http://iri-playbook.readthedocs.io/en/master/appendix.html#options\n\n\
Select/unselect options using space and click Enter to proceed.\n" 24 78 5 \
        "ENABLE_NELSON"       "Enable Nelson auto-peering" OFF \
        "ENABLE_FIELD"        "Enable CarrIOTA Field"      OFF \
        "ENABLE_HAPROXY"      "Enable HAProxy"             OFF \
        "DISABLE_MONITORING"  "Disable node monitoring"    OFF \
        "DISABLE_ZMQ_METRICS" "Disable ZMQ metrics"        OFF \
        3>&1 1>&2 2>&3)

    RC=$?
    if [[ $RC -ne 0 ]]; then
        echo "Installation cancelled"
        exit 1
    fi

    read -a RESULTS_ARRAY <<< "$RESULTS"
    for CHOICE in "${RESULTS_ARRAY[@]}"
    do
        case $CHOICE in
            '"DISABLE_MONITORING"')
                SKIP_TAGS+=",monitoring_role"
                ;;
            '"DISABLE_ZMQ_METRICS"')
                INSTALL_OPTIONS+=" -e iri_zmq_enabled=false"
                ;;
            '"ENABLE_NELSON"')
                INSTALL_OPTIONS+=" -e nelson_enabled=true"
                ;;
            '"ENABLE_FIELD"')
                INSTALL_OPTIONS+=" -e field_enabled=true"
                ;;
            '"ENABLE_HAPROXY"')
                INSTALL_OPTIONS+=" -e lb_bind_address=0.0.0.0"
                ;;
            *)
                ;;
        esac
    done

    if [[ -n "$RESULTS" ]]; then
        RESULTS_MSG=$(echo "$RESULTS"|sed 's/ /\n/g')
        if ! (whiptail --title "Confirmation" \
                 --yesno "You chose:\n\n$RESULTS_MSG\n\nPlease confirm you want to proceed with the installation?" \
                 --defaultno \
                 16 78); then
            exit 1
        fi
    fi
    INSTALL_OPTIONS+=" $SKIP_TAGS"
}

# Get primary IP from ICanHazIP, if it does not validate, fallback to local hostname
function set_primary_ip()
{
  echo "Getting external IP address..."
  local ip=$(curl -s -f --max-time 10 --retry 2 -4 'https://icanhazip.com')
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Got IP $ip"
    PRIMARY_IP=$ip
  else
    PRIMARY_IP=$(hostname -I|tr ' ' '\n'|head -1)
    echo "Failed to get external IP... using local IP $PRIMARY_IP instead"
  fi
}

function display_requirements_url() {
    echo "Please check requirements here: http://iri-playbook.readthedocs.io/en/master/requirements.html#the-requirements"
}

function check_arch() {
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        echo "ERROR: $ARCH architecture not supported"
        display_requirements_url
        exit 1
    fi
}

function set_ssh_port() {
    SSH_PORT=$(whiptail --inputbox "Please verify this is your active SSH port:" 8 78 "$SSH_PORT" --title "Verify SSH Port" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]] || [[ "$SSH_PORT" == "" ]]; then
        set_ssh_port
    elif [[ "$SSH_PORT" =~ [^0-9] ]] || [[ $SSH_PORT -gt 65535 ]] || [[ $SSH_PORT -lt 1 ]]; then
        whiptail --title "Invalid Input" \
                 --msgbox "Invalid input provided. Only numbers are allowed (1-65535)." \
                  8 78
        set_ssh_port
    fi
}

# Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [ "$VER" != "7" ]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_centos
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17|18) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_ubuntu
else
    echo "$OS not supported"
    exit 1
fi

set +o pipefail
# Get default SSH port
SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk {'print $2'})
set -o pipefail
if [[ "$SSH_PORT" != "" ]] && [[ "$SSH_PORT" != "22" ]]; then
    set_ssh_port
else
    SSH_PORT=22
fi
echo "SSH port to use: $SSH_PORT"

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

# Backup any existing iri-playbook directory
if [ -d iri-playbook ]; then
    echo "Backing up older iri-playbook directory..."
    rm -rf iri-playbook.backup
    mv iri-playbook iri-playbook.backup
fi

# Clone the repository (optional branch)
git clone $GIT_OPTIONS https://github.com/nuriel77/iri-playbook.git
cd iri-playbook

# Let user choose installation add-ons
set_selections

# web access (ipm, haproxy and grafana)
get_admin_password
echo -e "\nRunning playbook..."

# Ansible output log file
LOGFILE=/tmp/iri-playbook-$(date +%Y%m%d%H%M).log

# Override ssh_port
[[ $SSH_PORT -ne 22 ]] && echo "ssh_port: ${SSH_PORT}" > group_vars/all/z-ssh-port.yml

# Run the playbook
echo "*** Running playbook command: ansible-playbook -i inventory -v site.yml -e "memory_autoset=true" $INSTALL_OPTIONS" | tee -a "$LOGFILE"
set +e
unbuffer ansible-playbook -i inventory -v site.yml -e "memory_autoset=true" $INSTALL_OPTIONS | tee -a "$LOGFILE"
RC=$?
if [ $RC -ne 0 ]; then
    echo "ERROR! The playbook exited with failure(s). A log has been save here '$LOGFILE'"
    exit $RC
fi
set -e

# Calling set_primary_ip
set_primary_ip

# Add notice to set payout address for Field
if [[ "$INSTALL_OPTIONS" =~ field_enabled=true ]]; then
    FIELD_NOTICE="* Don't forget to set your payout address for Field in '/etc/field/field.ini'"
fi

OUTPUT=$(cat <<EOF
* A log of this installation has been saved to: $LOGFILE

* You should be able to connect to IOTA Peer Manager pointing your browser to:

http://${PRIMARY_IP}:8811

* You can reach the monitoring (grafana) graphs at:

http://${PRIMARY_IP}:5555/dashboard/db/iota?refresh=30s&orgId=1

* Note that your IP might be different as this one has been auto-detected in best-effort.

* You can use the username 'iotapm' and the password you entered during the installation.

${FIELD_NOTICE}

Please refer to the tutorial for post-installation information:
http://iri-playbook.readthedocs.io/en/master/post-installation.html

EOF
)

HEIGHT=$(expr $(echo "$OUTPUT"|wc -l) + 10)
whiptail --title "Installation Done" \
         --msgbox "$OUTPUT" \
         $HEIGHT 78

