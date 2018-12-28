.. _installation:

Installation
************

If you have little to no experience with Linux, I recommend you use the :ref:`getting_started_quickly`.

To prepare for running the automated "playbook" from this repository you require some basic packages.
First, it is always a good practice to check for updates on the server.

.. warning::

  All web pages served by this installer will be served on HTTPS with **self-signed certificates**. The browser will issue a warning when you connect for the first time. You can proceed and add the sites certificate as an exception. If you want valid certificates you can refer to :ref:`serverHTTPS` and search for the "Let's Encrypt" link.


Update System Packages
======================

For **Ubuntu** we type:

.. code-block:: bash

   apt-get update

and for **CentOS**:

.. code-block:: bash

   yum update


This will search for any packages to update on the system and require you to confirm the update.

Reboot Required?
----------------

Sometimes it is required to reboot the system after these updates (e.g. kernel updated).

For **Ubuntu** we can check if a reboot is required. Issue the command ``ls -l /var/run/reboot-required``::

  # ls -l /var/run/reboot-required
  -rw-r--r-- 1 root root 32 Dec  8 10:09 /var/run/reboot-required


If the file is found as seen here, you can issue a reboot (``shutdown -r now`` or simply ``reboot``).

For **Centos** we have a few options how to check if a reboot is required.

One of these options requires to install ``yum-utils``::

  yum install yum-utils -y

Once installed, we can run ``needs-restarting  -r``::

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


As you can see, a reboot is required (do so by issuing a ``reboot`` or ``shutdown -r now``)


Installing Ansible
==================
Ansible is an awesome software used to automate configuration and/or deployment of services.
This repository contains what Ansible refers to as a "Playbook" which is a set of instructions on how to configure the system.

This playbook installs required dependencies, the IOTA IRI package and IOTA Peer Manager.
In addition, it configures firewalls and places some handy files for us to control these services.

To install Ansible on **Ubuntu** I refer to the `official documentation <http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-apt
-ubuntu>`_:

.. code:: bash

   apt-get upgrade -y && apt-get clean && apt-get update -y && apt-get install software-properties-common -y && apt-add-repository ppa:ansible/ansible -y && apt-get update -y && apt-get install ansible git nano -y


For **CentOS**, simply run:

.. code:: bash

   yum install ansible git nano -y

You will notice I've added 'git' which is required (at least on CentOS it doesn't have it pre-installed as in Ubuntu).
In addition, I've added 'nano' which is helpful for beginners to edit files with (use vi or vim if you are adventurous).

.. note::

  See :ref:`usingNano` for instructions on how to use ``nano``.


Cloning the Repository
======================
To clone, run:

.. code:: bash

   cd /opt && git clone https://github.com/nuriel77/iri-playbook.git && cd iri-playbook

This will pull the repository to the directory in which you are and move you into the repository's directory.

Configuring Values
==================

In these two variable files you will find some configuration parameters for the installation. You can edit those using "nano" (see Note below).

.. code:: bash

   group_vars/all/iri.yml

and

.. code:: bash

   group_vars/all/iotapm.yml

.. note::

  To edit files you can use ``nano`` which is a simple editor. See :ref:`usingNano` for instructions.


Configure Memory Limits
------------------------

In **group_vars/all/iri.yml**:

The options ``iri_java_mem`` and ``iri_init_java_mem`` in the configuration files can determine what are the memory usage limits for IRI.

Depending on how much RAM your server has, you should set these accordingly.

For example, if your server has 4096MB (4GB memory), a good setting would be:

.. code:: bash

   iri_java_mem: 3072m
   iri_init_java_mem: 256m

Just leave some room for the operating system and other processes.
You will also be able to tweak this after the installation, so don't worry about it too much.

.. note::

  For the click-'n-go installation, these values are automatically configured. You can choose to auto-configure those values:
  When running the playbook (later in this guide) you can add ``-e "memory_autoset=true"`` to the ansible-playbook command.



Set Access Password
-------------------

This user name and password are used for all web-based authentications (e.g. Peer Manager, Monitoring Graphs).

Create a new variable file called **group_vars/all/z-override.yml** and set a user and a (strong!) password of your choice:

.. code:: bash

   iotapm_nginx_user: someuser
   iotapm_nginx_password: 'put-a-strong-password-here'


You can always add new users after the installation has finished:

.. code:: bash

   htpasswd /etc/nginx/.htpasswd newuser

Replace 'newuser' with the user name of your choice. You will be prompted for a password.

To remove a user from authenticating:

.. code:: bash

   htpasswd -D /etc/nginx/.htpasswd username


.. note::

  This username and password will also be used for Grafana (monitoring graphs)


.. _multipleHosts:

Configure Multiple Fullnodes
----------------------------

You can skip this section and proceed to "Running the Playbook" below if you are only installing on a single server.

The nice thing about Ansible's playbooks is the ability to configure multiple nodes at once.

You can have hundreds of fullnodes installed simultaneously!

To configure multiple hosts you need to use their IP addresses or hostnames (hostnames must resolve to their respective IP).

Edit the file ``inventory``. Here's an example of how we would list four hosts, using hostname and/or IP::

  [fullnode]
  localhost        ansible_connection=local
  iota01.tangle.io ansible_user=john
  iota02.tangle.io ansible_user=root
  10.20.30.40      ansible_ssh_port=9922

A requirement is that you can SSH access these servers from the server you are working on. Please check :ref:`configMultipleSSHHost` for more information.


Running the Playbook
====================

Two prerequisites here: you have already installed Ansible and cloned the playbook's repository.

By default, the playbook will run locally on the server where you've cloned it to.
You can run it:

.. code:: bash

   ansible-playbook -i inventory site.yml

Or, for more verbose output add the `-v` flag:

.. code:: bash

   ansible-playbook -i inventory -v site.yml


This can take a while as it has to install packages, download IRI and compile it.
Hopefully this succeeds without any errors (create a git Issue if it does, I will try to help).

Final Steps
-----------

Please go over the :ref:`post_installation` chapters to verify everything is working properly and start adding your first neighbors!

Also note that after having added neighbors, it might take some time to fully sync the node, or read below the "Fully Synchronized Database Download" section.

If you installed `monitoring` and `IOTA Peer Manager` you should be able to access those::

  Peer Manager: http://your-external-ip:8811
  Grafana: http://your-external-ip:5555

Use the username and password from ``group_vars/all/z-override.yml`` if you set it there previously.

If you followed the Getting Started Quickly guide, you configured a password during the installation, and you can use user ``iotapm``.


To configure an email for alerts see :ref:`alerting`.


Fully Synchronized Database Download
------------------------------------
In order to get up to speed quickly you can download a fully sycned database. Please check :ref:`getFullySyncedDB`


.. _installComponents:

Installing Only IOTA Peer Manager or Monitoring
===============================================

It is possible to install individual components from the playbook. For example, if you already have installed IRI following a different guide/method, you can use this playbook to install the full node monitoring graphs or IOTA Peer Manager.


Overview
--------

* IOTA Peer Manager is a GUI to help monitor, add and remove neighbors: `IOTA Peer Manager <https://github.com/akashgoswami/ipm>`_.

* The full node monitoring includes monitoring and graphs for IRI and your node: `IOTA Exporter <https://github.com/crholliday/iota-prom-exporter>`_.

.. note::

  If you haven’t already, just make sure your server matches the :ref:`requirements`.


* IOTA Peer Manager doesn't require to be served via a webserver. It is however the recommeneded method, unless you want to use SSH tunnel.

* At this stage, the full node monitoring graphs require to be served via a webserver (nginx), which will be installed via this playbook.


.. warning::

  By installing either Peer Manager and/or the full node monitorting, the firewall will be configured and enabled.
  It is strongly discouraged to run a server without the firewall enabled. Therefore, this playbook does not support running without a firewall.


Updates
-------

In order to install IOTA Peer Manager or fullnode monitoring, some packages and updates are required.


For **Ubuntu**:

.. code:: bash

   apt-get upgrade -y && apt-get clean && apt-get update -y && apt-get install software-properties-common -y && apt-add-repository ppa:ansible/ansible -y && apt-get update -y && apt-get install ansible git -y


For **CentOS**:

.. code:: bash

  yum install git ansible curl -y


Installation
------------
Clone this playbook to ``/opt``:

.. code:: bash

  cd /opt && git clone https://github.com/nuriel77/iri-playbook.git && cd iri-playbook

This assumes that you haven't already cloned the repository to this location. If you have, you should enter the ``/opt/iri-playbook`` directory and run a ``git pull``.


Some parameters require configuration before the installation. Both IOTA Peer Manager and the fullnode monitoring need to know on which port to access IRI API.

This is usually port 14265.

Note that in those two steps we are configurinig the variables files directly. Please consider using an override-file to only edit those parameters you need. This will avoid conflicts when updating new versions of the playbook. See :ref:`overrideFile`.

1. Edit ``edit group_vars/all/iri.yml`` and make sure the ``iri_api_port:`` option points to the correct IRI API port. In addition, ensure that ``iri_udp_port`` and ``iri_tcp_port`` match the ports your IRI is using for neighbor peering.

2. Edit ``group_vars/all/iotapm.yml``. Find ``install_nginx: true`` and set it to ``false`` if you don't want to install nginx to serve these services via webserver. If you choose to install nginx, leave it as ``true`` (if you already have nginx installed, just leave it as ``true``).

As mentioned earlier: currently, the fullnode monitoring depends on nginx being installed.

3. In the same file ``group_vars/all/iotapm.yml``, if using nginx, edit ``iotapm_nginx_user`` and ``iotapm_nginx_password``. These will set the user and password with which you will be able to access Peer Manager and/or the fullnode monitoring graphs.


* To install **IOTA Peer Manager only**, run:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --tags=iri_firewalld,iri_ufw,iri_ssl,iotapm_role


* To install **full node monitoring only**, run:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --skip-tags=iotapm_npm --tags=deps,iri_firewalld,iri_ufw,iri_ssl,iotapm_deps,monitoring_role


* To install **both Peer Manager and fullnode monitoring**, run:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --tags=deps,iri_firewalld,iri_ufw,iri_ssl,iotapm_role,monitoring_role



Access
------
To access the **fullnode monitoring graphs**, point your browser to ``http://YOUR-IP:5555`` and use the username and password you've configured earlier to log in.

To access the **IOTA Peer Manager** (assuming you've installed nginx), point your browser to ``http://YOUR-IP:8811`` and use the username and password you've configured earlier to log in.

If you haven't install nginx and want to access IOTA Peer Manager, it is not configured to be accessible externally by default. It would pose a security risk to your server running it exposed and not locked with a password. As an alternative you can use a SSH tunnel to bind to it (port 8011). See :ref:`tunnelingIriApiForWalletConnections`.


Install Nelson
==============

It is possible to install `Nelson <https://github.com/SemkoDev/nelson.cli>`_ as part of this installation.

.. warning::

  Nelson is still at beta stage.


Nelson depends on IRI being installed and running. Please check ``/opt/iri-playbook/group_vars/all/nelson.yml`` and configure to match your environment.

If you installed using the Getting Started Quickly chapter, you can just proceed to the installation below.

Installation
------------

* If you installed this playbook before Nelson was added you need to update the git repository. Run:

.. code:: bash

   cd /opt/iri-playbook && git pull


* To install Nelson, run:

.. code:: bash

   cd /opt/iri-playbook && ansible-playbook -i inventory -v site.yml --tags=nelson_role -e "nelson_enabled=true"

You can stop, start and restart nelson via ``systemctl (start|stop|restart) nelson``.

Join the ``#nelson-peering`` channel on IOTA's Discord if you have questions regarding Nelson.


Upgrade Nelson Version
----------------------

Run the upgrade command:

.. code:: bash

  cd /opt/iri-playbook && ansible-playbook -i inventory -v site.yml --tags=nelson_role -e "upgrade_nelson=true" -e "nelson_enabled=true"


View Status/Logs and configuration
----------------------------------

* To view nelson status run: ``systemctl status nelson``.

* To view nelson logs run: ``journalctl -u nelson``.

Or ``journalctl --no-pager -n50 -u nelson`` to view 50 last lines of Nelson's log.


* Nelson's configuration file can be found here: ``/etc/nelson/nelson.ini``.

* Nelson's data directory can be found here: ``/var/lib/nelson/data``.

