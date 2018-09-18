.. _installation:

Installation
************

The **proper** way to install the node is using the :ref:`getting_started_quickly`.

The following documentation is provided as reference for those with good experience with Linux and Ansible, or for those who would like to install multiple nodes at once.


Update System Packages
======================

To prepare for running the automated "playbook" from this repository you require some basic packages, as shown below.

For **Ubuntu/Debian** we type:

.. code-block:: bash

   apt-get update

and for **CentOS**:

.. code-block:: bash

   yum update


This will search for any packages to update on the system and require you to confirm the update.

Reboot Required?
----------------

Sometimes it is required to reboot the system after these updates (e.g. kernel updated).

For **Ubuntu/Debian** we can check if a reboot is required. Issue the command ``ls -l /var/run/reboot-required``::

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

To install Ansible on **Ubuntu** please refer to the `official documentation <http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-apt
-ubuntu>`_

To install Ansible on **Debian** please refer to the `official documentation <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-debian>`_

Hereby a one-liner to install Ansible on Ubuntu:

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

If you need to change a branch (e.g. to test a new feature), for example to a branch called ``feat/docker`` you can run:

.. code:: bash

  git checkout feat/docker



Configuring Values
==================

The directory containing all variable files are in ``group_vars/all/*.yml``. You will find some configuration parameters for the installation in those files.

**Please don't edit those files directly** but copy the files to ``group_vars/all/z-iri-override.yml`` (depending on the name of the original file) and edit the options there. This will effectively override existing variables from other files. Hence the usage of ``z-`` as the files get loaded in an alphabetic order, it ensures the variables will be overridden.


.. note::

  To edit files you can use ``nano`` which is a simple editor. See :ref:`usingNano` for instructions.


Configure Memory Limits
------------------------

In **group_vars/all/iri.yml** (don't forget to copy the file to ``group_vars/all/z-iri-override.yml`` and edit values there):

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

If you haven't done so already, create a new variable file called **group_vars/all/z-override.yml** and set a user and a (strong!) password of your choice:

.. code:: bash

   fullnode_user: someuser
   fullnode_user_password: 'put-a-strong-password-here'


You can always add new users after the installation has finished:

.. code:: bash

   htpasswd /etc/nginx/.htpasswd newuser

Replace 'newuser' with the user name of your choice. You will be prompted for a password.

To remove a user from authenticating:

.. code:: bash

   htpasswd -D /etc/nginx/.htpasswd username


.. note::

  This username and password will also be used for Grafana (monitoring graphs)



Extra Configuration Options
---------------------------

Some extra configuration options can be specified, for example:

Ensure Docker is installed:

.. code:: bash

  echo "install_docker: true" >>/opt/iri-playbook/group_vars/all/z-iri-override.yml

Ensure nginx is installed:

.. code:: bash

  echo "install_nginx: true" >>/opt/iri-playbook/group_vars/all/z-iri-override.yml


Ensure HAProxy is enabled:

.. code:: bash

  echo "lb_bind_address: 0.0.0.0" >>/opt/iri-playbook/group_vars/all/z-iri-override.yml

Enable memory auto-configuration:

.. code:: bash

  echo "memory_autoset: True" >>/opt/iri-playbook/group_vars/all/z-iri-override.yml



.. _multipleHosts:

Configure Multiple Fullnodes
----------------------------

You can skip this section and proceed to "Running the Playbook" below if you are only installing on a single server.

The nice thing about Ansible's playbooks is the ability to configure multiple nodes at once. You can have hundreds of fullnodes installed simultaneously!

Please make sure you configure some options as shown above into the variable override file.

To configure multiple hosts you need to use their IP addresses or hostnames (hostnames must resolve to their respective IP).

Edit the file ``inventory``. Here's an example of how we would list four hosts, using hostname and/or IP::

  [fullnode]
  localhost        ansible_connection=local
  iota01.tangle.io ansible_user=john
  iota02.tangle.io ansible_user=root
  10.20.30.40      ansible_ssh_port=9922

  [fullnode:vars]
  # Only add this line for Ubuntu and Debian
  ansible_python_interpreter=/usr/bin/python3
  # Only set this line if you didn't ssh to the servers previously
  # from the node where you are about to run the playbook from:
  ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'


At this stage management of multiple nodes is not centralized. You'll have to manage each node separately (downloading a fully synced database, configuring neighbors etc).


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

If you installed `monitoring` and `IOTA Peer Manager` you should be able to access those (ignore the warning about invalid certificates)::

  Peer Manager: https://your-external-ip:8811
  Grafana: https://your-external-ip:5555

Use the username and password from ``group_vars/all/z-override.yml`` if you set it there previously.

If you followed the Getting Started Quickly guide, you've configured a username and password during the installation.


To configure an email for alerts see :ref:`alerting`.


Fully Synchronized Database Download
------------------------------------

In order to get up to speed quickly you can download a fully synced database. Please check :ref:`getFullySyncedDB`
