![IOTA](https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Iota_logo.png/320px-Iota_logo.png)

# Welcome to the IOTA Full Node Installation wiki!

For a "click-'n-go" installation skip to: [Getting Started Quickly](#getting-started-quickly)

In this installation we:
- Automate the installation
- Take care of firewalls
- Automatically configure the java memory limit based on your system's RAM
- Explain how to connect a wallet to your full node
- Install IOTA Peer Manager
- Make IOTA Peer Manager accessible via the browser
- Password protect IOTA Peer Manager
- **NEW**: Install monitoring graphs (big thanks to Chris Holliday's IOTA exporter: https://github.com/crholliday/iota-prom-exporter)

Work in progress:
- Integrate alerting/notifications when node is not healthy
- Instead of compiling IRI, download the jar to expedite the installation a bit
- Security hardening steps
- Make it possible to install graphs for those who already did this installation. At the moment nodejs version will conflict.

***

#### Table of Contents 

 * [Introduction](#introduction)
 * [Getting Started Quickly](#getting-started-quickly)
 * [The Requirements](#the-requirements)
     * [Virtual Private Server](#virtual-private-server)
     * [Operating System](#operating-system)
     * [Accessing the VPS](#accessing-the-vps)
     * [System User](#system-user)
 * [Installation](#installation)
     * [Update System Packages](#update-system-packages)
     * [Installing Ansible](#installing-ansible)
     * [Cloning the Repository](#cloning-the-repository)
     * [Configuring Values](#configuring-values)
         * [Set IOTA PM Access Password](#set-iota-pm-access-password)
     * [Running the Playbook](#running-the-playbook)
 * [Post Installation](#post-installation)
     * [Controlling IRI](#controlling-iri)
     * [Controlling IOTA Peer Manager](#controlling-iota-peer-manager)
     * [Checking Ports](#checking-ports)
     * [Checking IRI Full Node Status](#checking-iri-full-node-status)
     * [Connecting to IOTA Peer Manager](#connecting-to-iota-peer-manager)
     * [Adding or Removing Neighbors](#adding-or-removing-neighbors)
     * [Install IOTA Python libs](#install-iota-python-libs)
 * [Full Node Remote Access](#full-node-remote-access)
     * [Tunneling IRI API for Wallet Connection](#tunneling-iri-api-for-wallet-connection)
     * [Peer Manager Behind WebServer with Password](#peer-manager-behind-webserver-with-password)
     * [Limiting Remote Commands](#limiting-remote-commands)
 * [Files and Locations](#files-and-locations)
 * [Maintenance](#maintenance)
     * [Upgrade IRI](#upgrade-iri)
     * [Check Database Size](#check-database-size)
     * [Check Logs](#check-logs)
     * [Replace Database](#replace-database)
 * [FAQ](#faq)
 * [Command Glossary](#command-glossary)
 * [Donations](#donations)




# Introduction
My first [tutorial](https://x-vps.com/blog/?p=111) I wrote around August 2017. Due to the exponential growth of the community and users who want to run their own full node, I thought it is a good time to write a new, more comprehensive tutorial.

## Why Another Tutorial?

I am hoping this tutorial will come in handy for those who posses less or almost no skills with Linux. And indeed, this tutorial focuses on Linux -- as suggested by many other tutorials (and justifiably), Linux is the best way to go.

I found that many tutorials lack some basic system configuration and explanations thereof. For example, running IRI as an unprivileged user, configuring firewalls, how to connect to it remotely and so on.

A copy-paste tutorial is awesome, and as it so often happens, the user can miss on some basic technical explanation about the setup. While it is impossible to include a crash-course of Linux for the purpose of this tutorial, I will try to explain some basic concepts where I find that many users had troubles with.

## Disclaimer
- This tutorial is based on the repository's Ansible-playbook I provided. It has been tested on CentOS 7.4 and Ubuntu 16.04.
- This tutorial does not include information on how to harden security on your server.
- For some details I will leave it to you to google (for example, how to SSH access your server). Otherwise the tutorial becomes too lofty.
- I recommend that you use SSH key authentication to your server, disable root SSH access and disable password authentication. In addition, do not expose firewall ports if not necessary.
- I am not associated with the IOTA foundation. I am simply an enthusiastic community member.

Feel free to comment, create issues or contact me on IOTA's slack channel (nuriel77) for advice and information.

Good luck!






# Getting Started Quickly
You can skip most of the information in this tutorial should you wish to do so and go straight ahead to install the full node.

There are just two little things you need to do first:

Once you are logged in to your server, make sure you are root (run `whoami`).
If that is not the case run `sudo su -` to become root and enter the password if you are required to do so.

For **CentOS** you might need to install 'curl' and 'screen' before you can proceed:
```sh
yum install curl screen -y
```
If you are missing these utilities on **Ubuntu** you can install them:
```sh
apt-get install curl screen -y
```
**Important**: your server's installation of Ubuntu or CentOS must be a "clean" one -- no pre-installed cpanel, whcms, plesk and so on.

### Run the Installer!
First, let's ensure the installation is running within a "screen" session. This ensures that the installer stays running in the background if the connection to the server breaks:
```sh
screen -S iota
```

Now we can run the installer:
```sh
bash <(curl https://raw.githubusercontent.com/nuriel77/iri-playbook/master/fullnode_install.sh)
```
If during the installation you are requested to reboot the node, just do so and re-run the command above once the node is back.

That's it. You can proceed to the [Post Installation](#post-installation) for additional information on managing your node.

If you lost connection to your server during the installation, don't worry. It is running in the background because we are running it inside a "screen" session.

You can always "reattach" back that session when you re-connect to your server:
```sh
screen -r -d iota
```


#### Accessing Peer Manager
You can access the peer manager using the user 'iotapm' and the password you've configured during installation:
```sh
http://your-ip:8811
```

#### Accessing Monitoring Graphs
You can access the Grafana IOTA graphs using 'iotapm' and the password you've configured during the installaton 

Big thanks to Chris Holliday's amazing tool for node monitoring: https://github.com/crholliday/iota-prom-exporter
```sh
http://your-ip:5555
```



# Overview




This tutorial will help you setup a full node on a Linux system (Ubuntu or CentOS).
The git repository I have created includes an automated installation.
I hope to be adding other distributions like Debian in the future.

It will install IRI and IOTA peer manager, a web GUI with which you can view your neighbors, add or remove neighbors, view the sync etc.

# The Requirements

* [Virtual Private Server](#virtual-private-server)
* [Operating System](#operating-system)
* [Accessing the VPS](#accessing-the-vps)
* [System User](#system-user)

## Virtual Private Server
This is probably the best and most common option for running a full node.
I will not get into where or how to purchase a VPS (virtual private server). There are many companies offering a VPS for good prices. The basic recommendation is to have one with at least 4GB RAM, 2 cores and minimum 30GB harddrive (SSD preferably).

## Operating System
When you purchase a VPS you are often given the option which operating system (Linux of course) and which distribution to install on it. This tutorial currently supports CentOS (>=7) and Ubuntu (>=16).

**Important**: this installation does not support operating systems with pre-installed panels such as cpane, whcms, plesk etc. If you can, choose a "bare" system.

## Accessing the VPS
Once you have your VPS deployed, most hosting provide a terminal (either GUI application or web-based terminal). With the terminal you can login to your VPS's command line.
You probably received a password with which you can login to the server. This can be a 'root' password, or a 'privileged' user (with which you can access 'root' privileges).

The best way to access the server is via a Secure Shell (SSH).
If your desktop is Mac or Linux, this is native on the command line. If you use Windows, I recommend installing [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

There are plenty of tutorials on the web explaining how to use SSH (or SSH via Putty). Basically, you can use a password login or SSH keys (better).

## System User
Given you are the owner of the server, you should either have direct access to the 'root' account or to a user which is privileged.
It is often recommended to run all commands as the privileges user, prefixing the commands with 'sudo'. In this tutorial I will leave it to the user to decide. 

If you accessed the server as a privileged user, and want to become 'root', you can issue a `sudo su -`.
Otherwise, you will have to prefix most commands with `sudo`, e.g. 
```sh
sudo apt-get install somepackage
```


# Installation

To prepare for running the automated "playbook" from this repository you require some basic packages.
First, it is always a good practice to check for updates on the server.

* [Update System Packages](#update-system-packages)
* [Installing Ansible](#installing-ansible)
* [Cloning the Repository](#cloning-the-repository)
* [Configuring Values](#configuring-values)
    * [Set IOTA PM Access Password](#set-iota-pm-access-password)
* [Running the Playbook](#running-the-playbook)

## Update System Packages

For **Ubuntu** we can type:
```sh
apt-get update
```
and for **CentOS**:
```
yum update
```

This will search for any packages to update on the system and require you to confirm the update.

### Reboot Required?
Sometimes it is required to reboot the system after these updates (e.g. kernel updated).

For **Ubuntu** we can check if a reboot is required. Issue the command `ls -l /var/run/reboot-required`
```sh
# ls -l /var/run/reboot-required
-rw-r--r-- 1 root root 32 Dec  8 10:09 /var/run/reboot-required
```
If the file is found as seen here, you can issue a reboot (`shutdown -r now` or simply `reboot`).

For **Centos** we have a few options how to check if a reboot is required. A simple one I've learned of recently is to install yum-utils:
```sh
yum install yum-utils -y
```
There's a utility that comes with it, we can run `needs-restarting  -r`:
```sh
# needs-restarting  -r
Core libraries or services have been updated:
  systemd -> 219-42.el7_4.4
  glibc -> 2.17-196.el7_4.2
  linux-firmware -> 20170606-56.gitc990aae.el7
  gnutls -> 3.3.26-9.el7
  glibc -> 2.17-196.el7_4.2
  kernel -> 3.10.0-693.11.1.el7

Reboot is required to ensure that your system benefits from these updates.

More information:
https://access.redhat.com/solutions/27943
```
As you can see, a reboot is required (do so by issuing a `reboot` or `shutdown -r now`)


## Installing Ansible
Ansible is an awesome software used to automate configuration and/or deployment of services.
This repository contains what Ansible refers to as a "Playbook" which is a set of instructions on how to configure the system.

This playbook installs required dependencies, the IOTA IRI package and IOTA Peer Manager.
In addition, it configures firewalls and places some handy files for us to control these services.

To install Ansible on **Ubuntu** I refer to the [official documentation](http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-apt-ubuntu):
```sh
apt-get upgrade -y && apt-get clean && apt-get update -y && apt-get install software-properties-common -y && apt-add-repository ppa:ansible/ansible -y && apt-get update -y && apt-get install ansible git -y
```

For **CentOS**, simply run:
```sh
yum install ansible git nano -y
```
You will notice I've added 'git' which is required (at least on CentOS it doesn't have it pre-installed as in Ubuntu).
In addition, I've added 'nano' which is helpful for beginners to edit files with (use vi or vim if you are adventurous).

## Cloning the Repository
To clone, run:
```sh
git clone https://github.com/nuriel77/iri-playbook.git && cd iri-playbook
```
This will pull the repository to the directory in which you are and move you into the repository's directory.

## Configuring Values
There are some values you can tweak before the installation runs.
There are two files you can edit:
```sh
group_vars/all/iri.yml
```
and
```sh
group_vars/all/iotapm.yml
```
(Use 'nano' or 'vi' to edit the files)

These files have comments above each option to help you figure out if anything needs to be modified.
In particular, look at the `iri_java_mem` and `iri_init_java_mem`. Depending on how much RAM your server has, you should set these accordingly.

For example, if your server has 4096MB (4GB memory), a good setting would be:
```sh
iri_java_mem: 3072
iri_init_java_mem: 256
```
Just leave some room for the operating system and other processes.
You will also be able to tweak this after the installation, so don't worry about it too much.

### Set IOTA PM Access Password
Very important value to set before the installation is the password and/or username with which you can access IOTA Peer Manager on the browser.

Edit the `group_vars/all/iotapm.yml` file and set a user and (strong!) password of your choice:
```sh
iotapm_nginx_user: someuser
iotapm_nginx_password: 'put-a-strong-password-here'
```

If you already finished the installation and would like to add an additional user to access IOTA PM, run:
```sh
htpasswd /etc/nginx/.htpasswd newuser
```
Replace 'newuser' with the user name of your choice. You will be prompted for a password.

To remove a user from authenticating:
```sh
htpasswd -D /etc/nginx/.htpasswd username
```


## Running the Playbook
Two prerequisites here: you have already installed Ansible and cloned the playbook's repository.

By default, the playbook will run locally on the server where you've cloned it to.
You can run it:
```sh
ansible-playbook -i inventory site.yml
```
Or, for more verbose output add the `-v` flag:
```sh
ansible-playbook -i inventory -v site.yml
```

This can take a while as it has to install packages, download IRI and compile it.
Hopefully this succeeds without any errors (create a git Issue if it does, I will try to help).

Please go over the Post Installation chapters to verify everything is working properly and start adding your first neighbors!

Also note that after having added neighbors, it might take some time to fully sync the node.


# Post Installation
We can run a few checks to verify everything is running as expected.
First, let's use the 'systemctl' utility to check status of iri (this is the main full node application)

Using the `systemctl status iri` we can see if the process is `Active: active (running)`.

See examples in the chapters below:

* [Controlling IRI](#controlling-iri)
* [Controlling IOTA Peer Manager](#controlling-iota-peer-manager)
* [Checking Ports](#checking-ports)
* [Checking IRI Full Node Status](#checking-iri-full-node-status)
* [Connecting to IOTA Peer Manager](#connecting-to-iota-peer-manager)
* [Adding or Removing Neighbors](#adding-or-removing-neighbors)
* [Install IOTA Python libs](#install-iota-python-libs)


## Controlling IRI
Check status:
```sh
systemctl status iri
```

Stop:
```sh
systemctl stop iri
```

Start:
```sh
systemctl start iri
```

Restart:
```sh
systemctl restart iri
```

## Controlling IOTA Peer Manager
Check status:
```sh
systemctl status iota-pm
```

Stop:
```sh
systemctl stop iota-pm
```

Start:
```sh
systemctl start iota-pm
```

Restart:
```sh
systemctl restart iota-pm
```


## Checking Ports

IRI uses 3 ports by default:
1. UDP neighbor peering port
2. TCP neighbor peering port
3. TCP API port (this is where a light wallet would connect to or iota peer manageR)

You can check if IRI and iota-pm are "listening" on the ports if you run: 

`lsof -Pni|egrep "iri|iotapm"`.

Here is the output you should expect:
```sh
# lsof -Pni|egrep "iri|iotapm"
java     2297    iri   19u  IPv6  20331      0t0  UDP *:14600
java     2297    iri   21u  IPv6  20334      0t0  TCP *:14600 (LISTEN)
java     2297    iri   32u  IPv6  20345      0t0  TCP 127.0.0.1:14265 (LISTEN)
node     2359 iotapm   12u  IPv4  21189      0t0  TCP 127.0.0.1:8011 (LISTEN)
```

What does this tell us?
1. `*:<port number>` means this port is listening on all interfaces - from the example above we see that IRI is listening on ports TCP and UDP no. 14600
2. IRI is listening for API (or wallet connections) on a local interface (not accessible from "outside") no. 14265
3. Iota-PM is listening on local interface port no. 8011

This is great. We can now tell new neighbors to connect to our IP (what is your IP? If you have a static IP - which a VPS most probably has - you can view it by issuing a `ip a`).

For example:
```sh
ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8950 qdisc pfifo_fast state UP qlen 1000
    link/ether fa:16:3e:d6:6e:15 brd ff:ff:ff:ff:ff:ff
    inet 10.50.0.24/24 brd 10.50.0.255 scope global dynamic eth0
       valid_lft 83852sec preferred_lft 83852sec
    inet6 fe80::c5f4:d95b:ba52:865c/64 scope link
       valid_lft forever preferred_lft forever
```
See the IP address on `eth0`? (10.50.0.24) this is the IP address of the server.

**Yes** - for those of you who've noticed, this example is a **private** address. But if you have a VPS you should have a public IP.

I could tell neighbors to connect to my UDP port: `udp://10.50.0.14:14600` or to my TCP port: `tcp://10.50.0.14:14600`.

Note that the playbook installation automatically configured the firewall to allow connections to these ports. If you happen to change those, you will have to allow the new ports in the firewall (if you choose to do so, check google for iptables or firewalld commands).

## Checking IRI Full Node Status
The tool `curl` can issue commands to the IRI API.
For example, we can run:
```sh
curl -s http://localhost:14265 -X POST -H 'X-IOTA-API-Version: someval' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}' | jq
```
The output you will see is JSON format.
Using `jq` we can, for example, extract the fields of interest:
```sh
curl -s http://localhost:14265 -X POST -H 'X-IOTA-API-Version: someval' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}' | jq '.latestSolidSubtangleMilestoneIndex, .latestMilestoneIndex'
```

Something worth mentioning is: if you've just started up your IRI node (or restarted) you will see a matching low number for both _latestSolidSubtangleMilestoneIndex_ and _latestMilestoneIndex_.
This is expected, and after a while (10-15 minutes) your node should start syncing (given that you have neighbors).

## Connecting to IOTA Peer Manager

For IOTA Peer Manager, this installation has already configured it to be accessible via a webserver. See [Peer Manager Behind WebServer with Password](#peer-manager-behind-webserver-with-password)


## Adding or Removing Neighbors
In order to add neighbors you can either use the iota Peer Manager or do that on the command-line.

To use the command line you can use a script that was shipped with this installation, e.g:
```sh
nbctl -a -n udp://1.2.3.4:12345 -n tcp://4.3.2.1:4321
```
The script will default to connect to IRI API on `http://localhost:14265`. 

If you need to connect to a different endpoint you can provide it via `-i http://my-node-address:port`.

If you don't have this helper script you will need to run a `curl` command, e.g to add:
```sh
curl -H 'X-IOTA-API-VERSION: 1.4' -d '{"command":"addNeighbors", "uris":[
  "udp://neighbor-ip:port", "udp://neighbor-ip:port"
]}' http://localhost:14265
```
to remove:
```sh
curl -H 'X-IOTA-API-VERSION: 1.4' -d '{"command":"removeNeighbors", "uris":[
  "udp://neighbor-ip:port", "udp://neighbor-ip:port"
]}' http://localhost:14265
```



**Note**:
Adding or remove neighbors is done "on the fly", so you will also have to add (or remove) the neighbor(s) in the configuration file of IRI.

The reason to add it to the configuration file is that after a restart of IRI, any neighbors added with the peer manager will be gone.

In CentOS you can add neighbors to the file:
```sh
/etc/sysconfig/iri
```
In Ubuntu:
```sh
/etc/default/iri
```
Edit the `IRI_NEIGHBORS=""` value as shown in the comment in the file.


## Install IOTA Python libs
You can install the official iota.libs.py to use for various python scripting with IOTA and the iota-cli.

On **Ubuntu**:
```sh
apt-get install python-pip -y && pip install --upgrade pip && pip install pyota
```
You can test with the script that shipped with this installation (to reattach pending transactions):
```sh
reattach -h
```

On **CentOS** this is a little more complicated, and better install pyota in a "virtualenv":
```sh
cd ~
yum install python-pip gcc python-devel -y
virtualenv venv
source ~/venv/bin/activate
pip install pip --upgrade
pip install pyota
```
Now you can test by running the reattach script as shown above. Note that if you log in back to your node you will have to run the `source ~/venv/bin/activate` to switch to the new python virtual environment.



# Full Node Remote Access

There are basically two ways you can connect to the full node remotely. One is describe here, the other in the 'tunneling' chapter below.

IRI has a command-line argument ("option") `--remote`. What does it do?
By default, IRI's API port will listen on the local interface (127.0.0.1). This doesn't allow to connect to it externally.


By using the `--remote` option, you cause IRI to listen on the external IP.

For example:

 - on **CentOS** edit `/etc/sysconfig/iri`
 - on **Ubuntu** `/etc/default/iri`

Find the line:
```sh
OPTIONS=""
```
and add `--remote` to it:
```sh
OPTIONS="--remote"
```
Then restart iri: `systemctl restart iri`
After IRI initializes, you will see (by issuing `lsof -Pni|grep java`) that the API port is listening on your external IP.

**NOTE**: By default, this installation is set to _not_ allow external communication to this port for security reasons. Should you want to allow this, you need to allow the port in the firewall.

In **CentOS**:
```sh
firewall-cmd --add-port=14265/tcp --zone=public --permanent && firewall-cmd --reload
```
In **Ubuntu**:
```sh
ufw allow 14265/tcp
```

Now you should be able to point your (desktop's) light wallet to your server's IP:port (e.g. 80.120.140.100:14265)

More in this chapter:
* [Tunneling IRI API for Wallet Connection](#tunneling-iri-api-for-wallet-connection)
* [Peer Manager Behind WebServer with Password](#peer-manager-behind-webserver-with-password)
* [Limiting Remote Commands](#limiting-remote-commands)

## Tunneling IRI API for Wallet Connection

Another option for accessing IRI and/or the iota-pm GUI is to use a SSH tunnel.

SSH tunnel is created within a SSH connection from your computer (desktop/laptop) towards the server.

The benefit here is that you don't have to expose any of the ports or use the `--remote` flag. You use SSH to help you tunnel through its connection to the server in order to bind to the ports you need.

### Note
For IOTA Peer Manager, this installation has already configured it to be accessible via a webserver. See [Peer Manager Behind WebServer with Password](#peer-manager-behind-webserver-with-password)


What do you need to "forward" the IRI API?
* Your server's IP
* The SSH port (22 by default in which case it doesn't need specifying)
* The port on which IRI API is listening
* The port on which you want to access IRI API on (let's just leave it the same as the one IRI API is listening on)
A default installation would have IRI API listening on TCP port 14265.


In order to create the tunnel you need to run the commands below **from** your laptop/desktop and not on the server where IRI is running.


**For Windows desktop/laptop**

You can use Putty to create the tunnel/port forward - you can use [this example](http://realprogrammers.com/how_to/set_up_an_ssh_tunnel_with_putty.html) to get you going, just replace the MySQL 3306 port with that of IRI API.

**For any type of bash command line (Mac/Linux/Windows bash)**

Here is the tunnel we'd have to create (run this on our laptop/desktop)
```sh
ssh -p <ssh port> -N -L <iota-pm-port>:localhost:<iota-pm-port> <user-name>@<server-ip>
```
Which would look like:
```sh
ssh -p 22 -N -L 14265:localhost:14265 root@<your-server-ip>
```
Should it ask you for host key verification, reply 'yes'.

Once the command is running you will not see anything, but you can connect with your wallet.
Edit your wallet's "Edit Node Configuration" to point to a custom host and use `http://localhost:14265` as address.

To stop the tunnel simply press "Ctrl-C".

You can do the same using the IRI API port (14265) and use a light wallet from your desktop to connect to `http://localhost:14265`.


## Peer Manager Behind WebServer with Password
This installation also configured a webserver (nginx) to help access IOTA Peer Manager.
It also locks the page using a password, one which you probably configured earlier during the installation steps.

The IOTA Peer Manager can be accessed if you point your browser to: `http://your-server-ip:8811`.

Note: The port 8811 will be configured by default unless you changed this before the installation in the variables file.


## Limiting Remote Commands
There's an option in the configuration file which works in conjunction with the `--remote` option:

```sh
REMOTE_LIMIT_API="removeNeighbors, addNeighbors, interruptAttachingToTangle, attachToTangle, getNeighbors"
```

On CentOS edit `/etc/sysconfig/iri`, in Ubuntu `/etc/default/iri`.
This option excludes the commands in it for the remote connection. This is to protect your node.
If you make changes to this option, you will have to restart IRI (`systemctl restart iri`).

# Files and Locations
Some files have been mentioned above. Here's an overview:

IRI configuration file (changes require iri to restart)
```sh
Ubuntu: /etc/default/iri
CentOS: /etc/sysconfig/iri
```

IOTA Peer Manager configuration file (changes require iota-pm restart)
```sh
Ubuntu: /etc/default/iota-pm
CentOS: /etc/sysconfig/iota-pm
```

IRI installation path:
```sh
/var/lib/iri/target
```
# Maintenance

* [Upgrade IRI](#upgrade-iri)
* [Check Database Size](#check-database-size)
* [Check Logs](#check-logs)
* [Replace Database](#replace-database)

## Upgrade IRI
If a new version of IRI has been released, it should suffice to replace the jar file.
The jar file is located e.g.:
```sh
/var/lib/iri/target/iri-1.4.1.2.jar
```
Let's say you downloaded a new version iri-1.6.2.jar (latest release is available [here](https://github.com/iotaledger/iri/releases/latest))
You can download it to the directory:
```sh
cd /var/lib/iri/target/
curl https://github.com/iotaledger/iri/releases/download/v1.6.2/original-iri-1.6.2.jar --output iri-1.6.2.jar
```
Then edit the IRI configuration file:
In Ubuntu
```sh
/etc/default/iri
```
In CentOS
```sh
/etc/sysconfig/iri
```
And update the version line to match, e.g.:
```sh
IRI_VERSION=1.6.2
```
This requires a iri restart (systemctl restart iri).
**Note**: The foundation normally announces additional information regarding upgrades, for example whether to use the `--rescan` flag etc. Such options can be specified in the `OPTIONS=""` value in the same file.

## Check Database Size
You can check the size of the database:
```sh
# du -hs /var/lib/iri/target/mainnetdb/
4.9G    /var/lib/iri/target/mainnetdb/
```

## Check Logs
Follow the last 50 lines of the log (iri):
```sh
journalctl -n 50 -f -u iri
```
For iota-pm:
```sh
journalctl -n 50 -f -u iota-pm
```
Click 'Ctrl-C' to stop following and return to the prompt.

Alternatively, omit the `-f` and use `--no-pager` to view the logs.

## Replace Database
At any time you can remove the existing database and start sync all over again. This is required if you know your database is corrupt (don't assume, use the community's help to verify such suspicion) or if you want your node to sync more quickly.

To remove an existing database:

1. stop IRI: `systemctl stop iri`.

2. delete the database: `rm -rf /var/lib/iri/target/mainnet*`

3. start IRI: `systemctl start iri`

If you want to import an already existing database, check the [FAQ](#where-can-i-get-a-fully-synced-database-to-help-kick-start-my-node) -- there's information on who to do that.


# FAQ

* [How to tell if my node is synced](#how-to-tell-if-my-node-is-synced)
* [Why do I see the Latest Milestone as 243000](#why-do-I-see-the-latest-milestone-as-243000)
* [How do I tell if I am syncing with my neighbors](#how-do-i-tell-if-i-am-syncing-with-my-neighbors)
* [Why is latestSolidSubtangleMilestoneIndex always behind latestMilestoneIndex](#why-is-latestsolidsubtanglemilestoneindex-always-behind-latestmilestoneindex)
* [How to get my node swap less](#how-to-get-my-node-swap-less)
* [What are the revalidate and rescan options for](#what-are-the-revalidate-and-rescan-options-for)
* [Where can I get a fully synced database to help kick start my node](#where-can-i-get-a-fully-synced-database-to-help-kick-start-my-node)
* [I try to connect the light wallet to my node but get connection refused](#i-try-to-connect-the-light-wallet-to-my-node-but-get-connection-refused)

### How to tell if my node is synced
You can check that looking at iota-pm GUI.
Check if `Latest Mile Stone Index` and `Latest Solid Mile Stone Index` are equal:

![synced_milestone](https://x-vps.com/static/images/synced_milestones.png)

Another option is to run the following command on the server's command line (make sure the port matches your IRI API port):
```sh
curl -s http://localhost:14265   -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json'   -d '{"command": "getNodeInfo"}'| jq '.latestSolidSubtangleMilestoneIndex, .latestMilestoneIndex'
```
This will output 2 numbers which should be equal.

Note: that command will fail if you don't have `jq` installed.

You can install `jq`:

**Ubuntu**: `apt-get install jq -y`

**Centos**: `yum install jq -y`

Alternatively, use python:
```sh
curl -s http://localhost:14265   -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json'   -d '{"command": "getNodeInfo"}'|python -m json.tool|egrep "latestSolidSubtangleMilestoneIndex|latestMilestoneIndex"
```

### Why do I see the Latest Milestone as 243000
This is expected behavior of you restarted IRI recently. 
Depending on various factors, it might take up to 30 minutes for this number to clear and the mile stones start increasing.

### How do I tell if I am syncing with my neighbors
You can use IOTA Peer Manager. Have a look at the neighbors boxes. They normally turn red after a while if there's no sync between you and their node.
Here's an example of a healthy neighbor, you can see it is also sending new transactions (green line) and the value of New Transactions increases in time:

![health_neighbor](https://x-vps.com/static/images/healthy_neighbor.png)

### Why is latestSolidSubtangleMilestoneIndex always behind latestMilestoneIndex
This is probably the most frequent question being asked :)

At time of writing, and to the best of my knowledge, there is not one definitive answer. There are probably various factors that might keep the Solid milestone from ever reaching the latest one and thus remaining not fully synced.

I have noticed that this problem exacerbates when the database is relatively large (5GB+). This is mostly never a problem right after a snapshot, when things run much smoother. This might also be related to ongoing "bad" spam attacks directed against the network.

What helped my node to sync was: 
* [Lowering "swappiness" of my node](#how-to-get-my-node-swap-less)
* [Importing a fully synced database](#where-can-i-get-a-fully-synced-database-to-help-kick-start-my-node)
* Finding "healthier" neighbors. This one is actually often hard to ascertain -- who is "healthy", probably other fully synced nodes.


### How to get my node swap less
You can always completely turn off swap, which is not always the best solution. Using less swap (max 1GB) can be helpful at times to avoid some OOM killers (out-of-memory).

As a simple solution you can change the "swappiness" of your linux system.
I have a 8GB 4 core VPS, I lowered the swappiness down to 1. You can start with a value of 10, or 5.
Run these two commands:
```sh
echo "vm.swappiness = 1" >>/etc/sysctl.conf
sysctl -p
```

You might need to restart IRI in order for it to adapt to the new setting. Try to monitor the memory usage, swap in particular, e.g.:

```sh
free -m
              total        used        free      shared  buff/cache   available
Mem:           7822        3331         692         117        3798        4030
Swap:          3815           1        3814
```
You'll see that in this example nothing is being used. If a large "used" value appears for Swap, it might be a good idea to lower the value and restart IRI.


### What are the revalidate and rescan options for

Here's a brief explanation what each does, courtesy of Alon Elmaliah:

> **Revalidate** "drops" the stored solid milestone "table". So all the milestones are revalidated once the node starts (checks signatures, balances etc). This is used it you take a DB from someone else, or have an issue with solid milestones acting out.

> **Rescan** drops all the tables, except for the raw transaction trits, and re stores the transactions (refilling the metadata, address indexes etc) - this is used when a migration is needed when the DB schema changes mostly.



It is possible to add these options to the IRI configuration file (or startup command).

`--revalidate` or `--rescan`.

If you have used this installation's tutorial / automation, you will find the configuration file:
```sh
Ubuntu: /etc/default/iri
CentOS: /etc/sysconfig/iri
```
You will see the OPTIONS variable, so you can tweak it like so:
```sh
OPTIONS="--rescan"
```
and restart IRI to take effect: `systemctl restart iri`


### Where can I get a fully synced database to help kick start my node

There's a public node that makes a copy of the database once every hour.

https://iota.lukaseder.de/download.html

Please consider donating them some iotas for the costs involved in making this possible.

You can download the database using the following command:
```sh
cd /var/lib/iri/target
curl --output db.tar.gz https://iota.lukaseder.de/downloads/db.tar.gz
```
Unpack it:
```sh
tar zxvf db.tar.gz
```
Stop iri if its running:
```sh
systemctl stop iri
```
Remove older database:
```sh
rm -rf /var/lib/iri/target/mainnet*
```
Move new database to required location:
```sh
mv db/ mainnetdb
```
Delete the lock file:
```sh
rm -f mainnetdb/LOCK
```

Set correct ownership of database:
```sh
chown iri.iri mainnetdb -R
```

Start iri:
```sh
systemctl start iri
```

**Note**: there was some debate on the slack channel whether after having imported a foreign database if it is required to run IRI with the `--revalidate` or `--rescan` flags. Some said they got fully synced without any of these.

To shed some light on what these options actually do, you can read about it [here](#what-are-the-revalidate-and-rescan-options-for)

### I try to connect the light wallet to my node but get connection refused
There are commonly two reasons for this to happen:

If your full node is on a different machine from where the light wallet is running from, there might be a firewall between, or, your full node is not configured to accept external connections.

See [Full Node Remote Access](#full-node-remote-access)

# Command Glossary
This is a collection of most command commands to come in handy.

#### Check IRI's node status:
```sh
curl -s http://localhost:14265 -X POST -H 'X-IOTA-API-Version: someval' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}' | jq
```
#### Same as above but extract the milestones:
```sh
curl -s http://localhost:14265   -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json'   -d '{"command": "getNodeInfo"}'|python -m json.tool|egrep "latestSolidSubtangleMilestoneIndex|latestMilestoneIndex"
```
This is the nbctl script that shipped with this installation (use it with -h to get help):

#### Add neighbors:
```sh
nbctl -a -n udp://1.2.3.4:12345 -n tcp://4.3.2.1:4321
```

#### Remove neighbors:
```sh
nbctl -r -n udp://1.2.3.4:12345 -n tcp://4.3.2.1:4321
```

#### Check iri and iota-pm ports listening:
```sh
lsof -Pni|egrep "iri|iotapm
```

#### Check all ports on the node:
```sh
lsof -Pni
```

#### Following example is for opening a port in the firewall:

In **CentOS**:
```sh
firewall-cmd --add-port=14265/tcp --zone=public --permanent && firewall-cmd --reload
```
In **Ubuntu**:
```sh
ufw allow 14265/tcp
```

# Donations
If you liked this tutorial, and would like to leave a donation you can use this IOTA address:
```sh
LDWOMAW9IBFEPQ9DRMCIOLLOLVCWGT9OISWNXVQTXPQANRJNDRLNWZVITVBYLMVFSQQFNZXHXQYWLWHEXKWROI9FMZ
```
Thanks!
