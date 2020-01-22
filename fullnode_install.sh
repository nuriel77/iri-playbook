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
declare -g IRI_PLAYBOOK_DIR="/opt/iri-playbook"
declare -g INSTALLER_OVERRIDE_FILE="${IRI_PLAYBOOK_DIR}/group_vars/all/z-installer-override.yml"

if grep -q 'IRI PLAYBOOK' /etc/motd > /dev/null 2>&1; then
    :>/etc/motd
else
    if [ -f "$INSTALLER_OVERRIDE_FILE" ] && [ "$1" != "rerun" ]
    then
        if ! (whiptail --title "Confirmation" \
                 --yesno "It looks like a previous installation already exists.\n\nRunning the installer on an already working node is not recommended.\n\nIf you want to re-run only the playbook check the documentation or ask for assistance on Discord #fullnodes channel.\n\nPlease confirm you want to proceed with the installation?" \
                 --defaultno \
                 16 78); then
            exit 1
        fi
    fi
fi

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
4. If you already have a configured server, re-running this script will overwrite previous configuration.

EOF

read -p "Do you wish to proceed? [y/N] " yn
if echo "$yn" | grep -v -iq "^y"; then
    echo Cancelled
    exit 1
fi

#################
### Functions ###
#################
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

function wait_apt(){
    local i=0
    tput sc
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
        case $(($i % 4)) in
          0 ) j="-" ;;
          1 ) j="\\" ;;
          2 ) j="|" ;;
          3 ) j="/" ;;
        esac
        tput rc
        echo -en "\r[$j] Waiting for other software managers to finish..."
        sleep 0.5
        ((i=i+1))
    done
    echo
}

function init_centos_7(){
    echo "Updating system packages..."
    yum update -y

    echo "Install epel-release..."
    yum install epel-release -y

    echo "Update epel packages..."
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

function init_centos_8(){
    echo "Updating system packages..."
    dnf update -y --nobest

    echo "Install epel-release..."
    dnf install epel-release -y

    echo "Update epel packages..."
    dnf update -y --nobest

    echo "Install yum utils..."
    dnf install -y yum-utils

    local OUTPUT=$(needs-restarting)
    if [[ "$OUTPUT" != "" ]]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible, git and other requirements..."
    dnf install git expect newt python3-pip cracklib newt -y
    pip3 --disable-pip-version-check install ansible
}

function init_ubuntu(){
    wait_apt && echo "Ensure no package managers ..." && sleep 5 && wait_apt

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
    add-apt-repository universe -y
    apt-get update -y
    apt-get install ansible git expect-dev tcl libcrack2 cracklib-runtime whiptail -y
}

function init_debian(){
    wait_apt && echo "Ensure no package managers ..." && sleep 5 && wait_apt

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
    local ANSIBLE_SOURCE="deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
    grep -q "$ANSIBLE_SOURCE" /etc/apt/sources.list || echo "$ANSIBLE_SOURCE" >> /etc/apt/sources.list
    apt-get install dirmngr --install-recommends -y
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    apt-get update -y
    apt-get install ansible git expect-dev tcl libcrack2 cracklib-runtime whiptail -y
}

function inform_reboot() {
    cat <<EOF >/etc/motd
======================== IRI PLAYBOOK ========================

To proceed with the installation, please re-run:

bash <(curl -s https://raw.githubusercontent.com/nuriel77/iri-playbook/feat/docker/fullnode_install.sh)

(make sure to run it as user root)

EOF

cat <<EOF


======================== PLEASE REBOOT AND RE-RUN THIS SCRIPT =========================

Some system packages have been updated which require a reboot
and allow the node installer to proceed with the installation.

*** Please reboot this machine and re-run this script ***


>>> To reboot run: 'reboot', and when the server is back online:
bash <(curl -s https://raw.githubusercontent.com/nuriel77/iri-playbook/feat/docker/fullnode_install.sh)

!! Remember to run this command as user 'root' !!

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
        return
    fi

    PASSWD_CHECK=$(echo -n "$PASSWORD_A" | cracklib-check)
    if [[ $(echo "$PASSWD_CHECK" | awk {'print $2'}) != "OK" ]]; then
        whiptail --title "Weak Password!" \
                 --msgbox "Please choose a better password:$(echo ${PASSWD_CHECK}|cut -d: -f2-)" \
                 8 78
        get_admin_password
        return
    fi

    # Ensure we escape single quotes (using single quotes) because we need to
    # encapsulate the password with single quotes for the Ansible variable file
    PASSWORD_A=$(echo "${PASSWORD_A}" | sed "s/'/''/g")
    echo "fullnode_user_password: '${PASSWORD_A}'" >> "$INSTALLER_OVERRIDE_FILE"
    chmod 600 "$INSTALLER_OVERRIDE_FILE"
}

function set_admin_username() {
    ADMIN_USER=$(whiptail --inputbox "Choose an administrator's username.\nOnly valid ASCII characters are allowed:" 10 $WIDTH "$ADMIN_USER" --title "Choose Admin Username" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi

    local LC_CTYPE=C
    case "${ADMIN_USER}" in
        *[![:cntrl:][:print:]]*)
            whiptail --title "Invalid characters!!" \
                     --msgbox "Only ASCII characters are allowed:\n\n!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~" \
                     12 78
            set_admin_username
            return
            ;;
    esac

    echo "fullnode_user: '${ADMIN_USER}'" >> "$INSTALLER_OVERRIDE_FILE"

}

# Installation selection menu
function set_selections()
{
    local RC RESULTS RESULTS_ARRAY CHOICE SKIP_TAGS
    SKIP_TAGS="--skip-tags=_"

    RESULTS=$(whiptail --title "Installation Options" --checklist \
        --cancel-button "Exit" \
        "\nPlease choose additional installation options.\n(It is perfectly okay to leave this as is).\n\
For more information about these options visit this link:\n
http://iri-playbook.readthedocs.io/en/feat-docker/appendix.html#options\n\n\
Select/unselect options using space and click Enter to proceed.\n" 28 78 7 \
        "INSTALL_DOCKER"           "Install Docker runtime (recommended)" ON \
        "INSTALL_NGINX"            "Install nginx webserver (recommended)" ON \
        "USE_BRIDGED_NETWORK"      "Use Docker bridged network (less performance)" OFF \
        "SKIP_FIREWALL_CONFIG"     "Skip configuring firewall" OFF \
        "DISABLE_IOTACADDY"        "Disable IOTA Caddy PoW support" OFF \
        "ENABLE_HAPROXY"           "Enable HAProxy (recommended)" ON \
        "DISABLE_MONITORING"       "Disable node monitoring"    OFF \
        "DISABLE_ZMQ_METRICS"      "Disable ZMQ metrics"        OFF \
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
            '"INSTALL_DOCKER"')
                echo "install_docker: true" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"INSTALL_NGINX"')
                echo "install_nginx: true" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"USE_BRIDGED_NETWORK"')
                echo "iri_net_name: iri_net" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"SKIP_FIREWALL_CONFIG"')
                echo "configure_firewall: false" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"DISABLE_MONITORING"')
                SKIP_TAGS+=",monitoring_role"
                echo "disable_monitoring: true" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"DISABLE_ZMQ_METRICS"')
                echo "iri_zmq_enabled: false" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"DISABLE_IOTACADDY"')
                echo "iotacaddy_enabled: false" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"ENABLE_HAPROXY"')
                echo "lb_bind_addresses: ['0.0.0.0']" >>"$INSTALLER_OVERRIDE_FILE"
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

function skip_all_updates() {
    readarray -t TO_RUN_UPDATES < <(find "${IRI_PLAYBOOK_DIR}/custom_updates/" -maxdepth 1 -type f -name '*_updates.sh')

    # Return if nothing to update
    ((${#TO_RUN_UPDATES[@]} == 0)) && { clear; return; }

    for FILE in "${TO_RUN_UPDATES[@]}"
    do
        touch "${FILE}.completed"
    done
}

function run_playbook(){
    # Get default SSH port
    set +o pipefail
    SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk {'print $2'})
    set -o pipefail
    if [[ "$SSH_PORT" != "" ]] && [[ "$SSH_PORT" != "22" ]]; then
        set_ssh_port
    else
        SSH_PORT=22
    fi
    echo "SSH port to use: $SSH_PORT"

    # Ansible output log file
    LOGFILE=/var/log/iri-playbook-$(date +%Y%m%d%H%M).log

    # Override ssh_port
    [[ $SSH_PORT -ne 22 ]] && echo "ssh_port: \"${SSH_PORT}\"" > group_vars/all/z-ssh-port.yml

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

    # Check playbook needs reboot
    if [ -f "/var/run/playbook_reboot" ]; then
        cat <<EOF >/etc/motd
-------------------- IRI PLAYBOOK --------------------

It seems you have rebooted the node. You can proceed with
the installation by running the command:

${IRI_PLAYBOOK_DIR}/rerun.sh

(make sure you are user root!)

-------------------- IRI PLAYBOOK --------------------
EOF

        cat <<EOF
-------------------- NOTE --------------------

The installer detected that the server requires a reboot,
most probably to enable a functionality required for the playbook.

You can reboot the server using the command 'reboot'.

Once the server is back online you can use the following command
to proceed with the installation (become user root first):

${IRI_PLAYBOOK_DIR}/rerun.sh

-------------------- NOTE --------------------

EOF

        rm -f "/var/run/playbook_reboot"
        exit
    fi

    # Calling set_primary_ip
    set_primary_ip

    # Get configured username if missing.
    # This could happen on script re-run
    # due to reboot, therefore the variable is empty
    if [ -z "$ADMIN_USER" ]; then
        ADMIN_USER=$(grep "^fullnode_user:" $INSTALLER_OVERRIDE_FILE | awk {'print $2'})
    fi

    OUTPUT=$(cat <<EOF
* A log of this installation has been saved to: $LOGFILE

* You should be able to connect to IOTA Peer Manager and Grafana:

https://${PRIMARY_IP}:8811 and https://${PRIMARY_IP}:5555

* Note that your IP might be different as this one has been auto-detected in best-effort.

* Log in with username ${ADMIN_USER} and the password you have entered during the installation.

Please refer to the wiki for post-installation information:
https://iri-playbook.readthedocs.io/en/feat-docker

Thank you for installing an IOTA node with the IRI-playbook!

EOF
)

    HEIGHT=$(expr $(echo "$OUTPUT"|wc -l) + 10)
    whiptail --title "Installation Done" \
             --msgbox "$OUTPUT" \
             $HEIGHT 78
}

#####################
### End Functions ###
#####################

# Incase we call a re-run
if [[ -n "$1" ]] && [[ "$1" == "rerun" ]]; then
    run_playbook
    exit
fi

### Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [[ ! "$VER" =~ ^(7|8) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_centos_$VER
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17|18) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_ubuntu
elif [[ "$OS" =~ ^Debian ]]; then
    if [[ ! "$VER" =~ ^(9|10) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_debian
else
    echo "$OS not supported"
    exit 1
fi

echo "Verifying Ansible version..."
ANSIBLE_VERSION=$(ansible --version|head -1|awk {'print $2'}|cut -d. -f1-2)
if (( $(awk 'BEGIN {print ("'2.6'" > "'$ANSIBLE_VERSION'")}') )); then
    echo "Error: Ansible minimum version 2.6 required."
    echo "Please remove Ansible: (yum remove ansible -y for CentOS, or apt-get remove -y ansible for Ubuntu)."
    echo
    echo "Then refer to the documentation on how to get latest Ansible installed:"
    echo "http://docs.ansible.com/ansible/latest/intro_installation.html#latest-release-via-yum"
    echo "Note that for CentOS you may need to install Ansible from Epel to get version 2.6 or higher."
    exit 1
fi

echo "Git cloning iri-playbook repository..."
cd /opt

# Backup any existing iri-playbook directory
if [ -d iri-playbook ]; then
    echo "Backing up older iri-playbook directory..."
    rm -rf iri-playbook.backup
    mv -- iri-playbook "iri-playbook.backup.$(date +%s)"
fi

# Clone the repository (optional branch)
git clone $GIT_OPTIONS https://github.com/nuriel77/iri-playbook.git
cd "${IRI_PLAYBOOK_DIR}"

# first installation? Skip all upgrades
skip_all_updates

# Let user choose installation add-ons
set_selections

# Get the administrators username
set_admin_username

# web access (ipm, haproxy, grafana, etc)
get_admin_password

echo -e "\nRunning playbook..."
run_playbook
