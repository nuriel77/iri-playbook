.. _installation:

Installation
************

To prepare for running the automated "playbook" from this repository you require some basic packages.
First, it is always a good practice to check for updates on the server.

Update System Packages
======================

For **Ubuntu** we can type:

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

.. code-block:: bash

   yum install yum-utils -y

There's a utility that comes with it, we can run ``needs-restarting  -r``::

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

   apt-get upgrade -y && apt-get clean && apt-get update -y && apt-get install software-properties-common -y && apt-add-repository ppa:ansible/ansible -y && apt-get update -y && apt-get install ansible git -y


For **CentOS**, simply run:

.. code:: bash

   yum install ansible git nano -y

You will notice I've added 'git' which is required (at least on CentOS it doesn't have it pre-installed as in Ubuntu).
In addition, I've added 'nano' which is helpful for beginners to edit files with (use vi or vim if you are adventurous).


Cloning the Repository
======================
To clone, run:

.. code:: bash

   git clone https://github.com/nuriel77/iri-playbook.git && cd iri-playbook

This will pull the repository to the directory in which you are and move you into the repository's directory.

Configuring Values
==================
There are some values you can tweak before the installation runs.
There are two files you can edit:

.. code:: bash

   group_vars/all/iri.yml

and

.. code:: bash

   group_vars/all/iotapm.yml

(Use 'nano' or 'vi' to edit the files)

These files have comments above each option to help you figure out if anything needs to be modified.
In particular, look at the ``iri_java_mem`` and ``iri_init_java_mem``.
Depending on how much RAM your server has, you should set these accordingly.

For example, if your server has 4096MB (4GB memory), a good setting would be:

.. code:: bash

   iri_java_mem: 3072
   iri_init_java_mem: 256

Just leave some room for the operating system and other processes.
You will also be able to tweak this after the installation, so don't worry about it too much.

Set Access Password
-------------------
Very important value to set before the installation is the password and/or username with which you can access IOTA Peer Manager on the browser.

Edit the ``group_vars/all/iotapm.yml`` file and set a user and (strong!) password of your choice:

.. code:: bash

   iotapm_nginx_user: someuser
   iotapm_nginx_password: 'put-a-strong-password-here'


If you already finished the installation and would like to add an additional user to access IOTA PM, run:

.. code:: bash

   htpasswd /etc/nginx/.htpasswd newuser

Replace 'newuser' with the user name of your choice. You will be prompted for a password.

To remove a user from authenticating:

.. code:: bash

   htpasswd -D /etc/nginx/.htpasswd username



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

Please go over the Post Installation chapters to verify everything is working properly and start adding your first neighbors!

Also note that after having added neighbors, it might take some time to fully sync the node.

