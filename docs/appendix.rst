.. _appendix:

Appendix
********

This chapter includes additional configuration options and/or general systems configuration.

It is meant for more advanced usage.


Using Fully Qualified Domain Name for my server
===============================================

This requires that you have set up DNS service to point a fully qualified domain name to your server's IP address.

For example, ``x-vps.com`` points to 185.10.48.110 (if you simply ``ping x-vps.com`` you will see the IP address).

Instead of using the ports e.g. 8811 and 5555 with IP combination, we can use a FQDN, e.g. ``pm.example.com`` to reach peer manager on our server.

|


In this chapter we are going to configure nginx to serve IOTA Peer Manager and Grafana on port 80, while using a fully qualified domain name.


You should be able to create subdomains for your main domain name. For example, if your FQDN is "example.com", you can create in your DNS service an entry for::

  pm.example.com

and::

  grafana.example.com


Here's what you have to change:

For Peer Manager, edit the file ``/etc/nginx/conf.d/iotapm.conf``::

  upstream iotapm {
    server 127.0.0.1:8011;
  }

  server {
    listen 80;
    server_name pm.example.com;
    server_tokens off;

    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://iotapm;
    }
  }

Of course, don't forget to replace ``pm.example.com`` with your own FQDN e.g. ``pm.my-fqdn.com``.

Now, test nginx is okay with the change::

  nginx -t

Output should look like this::

  # nginx -t
  nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
  nginx: configuration file /etc/nginx/nginx.conf test is successful

Then, reload nginx configuration::

  systemctl reload nginx

You should be able to point your browser to ``http://pm.my-fqdn.com`` and see the Peer Manager.

.. note::

  For **Ubuntu** you will have to allow http port in ufw firewall:

  ufw allow http


  For **Centos**:

  firewall-cmd --add-service=http --permanent --zone=public && firewall-cmd --reload


The same can be done for grafana ``/etc/nginx/conf.d/grafana.conf``::

  upstream grafana {
      server 127.0.0.1:3000;
  }

  server {
      listen 80;
      server_name grafana.example.com;
      server_tokens off;

    location / {
        proxy_pass http://grafana;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
  }

Again, test nginx: ``nginx -t`` and reload nginx: ``systemctl reload nginx``.

Now you should be able to point your browser to ``http://grafana.my-fqdn.com``.


.. note::

  It is recommended to run your server using HTTPS. This could not be configured by default on the installer because of self-signed certificates.
  Browsers are not so keen on opening pages with self-signed certificates. While this should not be a problem when you know it is your server,
  I chose to skip this and keep this for advanced users.

  Using SSL/HTTPS makes it virtually impossible for someone to "sniff" passwords or sensitive information your browser passes to a server.



Configuring my server with HTTPS
================================

There are amazing tutuorials out there explaining how to achieve this. What is important to realize is that you can either create your own "self-signed" certificates (you become the Certificate Authority which isn't recognized by anyone else), or use valid certificate authorities.

`Let's Encrypt <https://letsencrypt.org/getting-started/>`_ is a free service which allows you to create a certificate per domain name. Other solution would be to purchase a certificates.

By having a "valid" certificate for your server (signed by a trusted authority), you will get the green lock next to the URL in the browser, indicating that your connection is secure.

Your connection will still be encrypted if you opt for a self-signed certificate. It is just so that the browser cannot verify who signed it.


Here is a great tutorial on how to add HTTPS to your nginx, for Ubuntu:

https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04

And for CentOS:

https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-centos-7

.. note::

  I encourage you to refer to the previous chapter about configuring FQDN for Peer Manager and Grafana. From there you can proceed to adding HTTPS to those configurations.



.. note::

  For **Ubuntu** you will have to allow https port in ufw firewall:

  ufw allow https


  For **Centos**:

  firewall-cmd --add-service=https --permanent --zone=public && firewall-cmd --reload


.. _revProxyWallet:

Reverse Proxy for IRI API (wallet)
==================================

If you read the two chapters above about configuring nginx to support FQDN or HTTPS you might be wondering whether you should reverse proxy from the web server to IRI API port (for wallet connections etc).

Here are my thoughts about it:

1. HTTPS servers two main purposes in this context: sending data encrypted and verifying the identity of the server. Is sending encrypted data important for a wallet? Well, not really, considering all the data is public. Unless you use ``--remote-auth`` or lock the API port with password (``htpasswd?``) there's no benefit in HTTPS. In my opinion, its just a nice-to-have. But maybe in the future as the network grows we will learn that using HTTPS is helpful for certificate/server validation.
 
2. Serving IRI API port via nginx, haproxy or other web-servers with proxy capabilities adds a few benefits. For example, better logging. IP blacklisting or whitelisting, inspecting headers and body/contents of the data.

.. warning::

  Please read the section below if you choose to reverse proxy to IRI API port.

Proxy Warning
^^^^^^^^^^^^^
Should you choose to reverse proxy from your webserver/loadbalancer/proxy to IRI API (on the same machine) there's something very important you need to take into account.

If you point your proxy to IRI API at address 127.0.0.1 (127.0.0.1:14265) anyone connecting can run any command they want. The reason is that IRI sees the connection originating from 127.0.0.1, thereby bypassing the limitations of LIMIT_REMOTE_API.

So, what to do about this?

Let's say your API port is 14265 and you only want people to connect via ``https://my.node-name.com:443``:

- If any rules in the firewall allow 14265, remove those.
- Make sure 443 (https) is allowed in the firewall.
- In the webserver/proxy configuration point the proxy to ``http://your-external-interface-ip-address:14265``.
- Ensure IRI is configured with the ``API_HOST = 0.0.0.0`` or ``--remote`` startup argument.

That's it. Now you might be wondering: "I didn't allow 14265 in the firewall, why should my nginx be able to connect to IRI on the external IP?".

It will succeed because the IP tables rule will only apply for external connections.




.. _alerting:

Sending Alert Notifications
===========================

Since release v1.1 a new feature has been introduced to support alerting.

.. warning::

   This is considered an advanced feature. Configuration hereof requires some basic Linux and system configuration experience.


.. note::

  To edit files you can use ``nano`` which is a simple editor. See :ref:`usingNano` for instructions.


TL;DR version
-------------

1. Edit the file ``/opt/prometheus/alertmanager/config.yml`` using nano or any other editor.

2. Find the following lines:

.. code:: bash

   # Send using postfix local mailer
   # You can send to a gmail or hotmail address
   # but these will most probably be put into junkmail
   # unles you configure your DNS and the from address
   - name: email-me
     email_configs:
     - to: root@localhost
       from: alertmanager@test001
       html: '{{ template "email.tmpl" . }}'
       smarthost: localhost:25
       send_resolved: true


3. Replace the email address in the line: ``- to: root@localhost`` with your email address.

4. Replace the email address in the line ``from: alertmanager@test001`` with your node's name, e.g: ``alertmanager@fullnode01``.

5. Save the file (in nano CTRL-X and confirm 'y')

6. Restart alertmanager: ``systemctl restart alertmanager``


**Note**

Emails generated by your server will most certainly end up in junk mail. The reason being that your server is not configured as verified for sending emails.

You can, alternatively, try to send emails to your gmail account if you have one (or any other email account).

You will find examples in the ``/opt/prometheus/alertmanager/config.yml`` on how to authenticate.



For more information about alertmanager's configuration consult the `documentation <https://prometheus.io/docs/alerting/configuration/#email_config>`_.


Configuration
-------------

The monitoring system has a set of default alerting rules. These are configured to monitor various data of the full node.

|

For example:

* CPU load high
* Memory usage high
* Swap usage high
* Disk space low
* Too few or too many neighbors
* Inactive neighbors
* Milestones sync

**Prometheus** is the service responsible for collecting metrics data from the node's services and status.

**Alert Manager** is the service responsible for sending out notifications.



Configuration Files
-------------------
It is possible to add or tweak existing rules:


Alerts
^^^^^^
The alerting rules are part of Prometheus and are configured in ``/etc/prometheus/alert.rules.yml``.

.. note::

   Changes to Prometheus's configuration requires a restart of prometheus.


Notifications
^^^^^^^^^^^^^
The configuration file for alertmanager can be found in ``/opt/prometheus/alertmanager/config.yml``.

This is where you can **set your email address and/or slack channel** (not from iota!) to where you want to send the notifications.

The email template used for the emails can be found in ``/opt/prometheus/alertmanager/template/email.tmpl``.


.. note::

   Changes to Alert Manager configuration files require a restart of alertmanager.


Controls
--------
Prometheus can be controlled via systemctl, for example:

.. code:: bash

   To restart: systemctl restart prometheus
   To stop: systemctl stop prometheus
   Status: systemctl status prometheus
   Log: journalctl -u prometheus

The same can be done with ``alertmanager``.


For more information see `Documentation Prometheus Alertmanager <https://prometheus.io/docs/alerting/alertmanager/>`_



Restart IRI On Latest Subtangle Milestone Stuck
===============================================

A trigger to restart IRI restart when the Latest Subtangle Milestone Stuck is stuck has been added to alertmanager.

If you don't have alert manager or had it installed before this feature was introduced, see :ref:`upgradeToFeature`.


.. warning::

   This feature is disabled by default as this is not considered a permanent or ideal solution. Please, first try to download a fully sycned database as proposed in the faq, or try to find "healthier" neighbors.


Enabling the Feature
--------------------

Log in to your node and edit the alertmanager configuration file: ``/opt/prometheus/alertmanager/config.yml``.

You will find the following lines::

  # routes:
  # - receiver: 'executor'
  #  match:
  #    alertname: MileStoneNoIncrease

Remove the ``#`` comments, resulting in::

  routes:
  - receiver: 'executor'
    match:
     alertname: MileStoneNoIncrease

Try not to mess up the indentation (should be 2 spaces to begin with).

After having applied the changes, save the file and restart alertmanager: ``systemctl restart alertmanager``.

What will happen next is that the service called ``prom-am-executor`` will be called and trigger a restart to IRI when the Latest Subtangle Milestone is stuck for more than ``30`` minutes.


.. note::

  This alert-trigger is set to only execute if the Latest Subtangle Milestone is stuck and not equal to 243000 (which is the case when starting up or restarting IRI).


Disabling the Feature
---------------------
A quick way to disable this feature:

.. code:: bash

   systemctl stop prom-am-executor && systemctl disable && prom-am-executor

To re-enable:

.. code:: bash

   systemctl enable prom-am-executor && systemctl start prom-am-executor


Configuring the Feature
-----------------------

You can choose to tweak some values for this feature, for example how long to wait on stuck milestones before restarting IRI:

Edit the file ``/etc/prometheus/alert.rules.yml``, find the alert definition::

    # If latest subtangle milestone doesn't increase for 30 minutes
    - alert: MileStoneNoIncrease
      expr: increase(iota_node_info_latest_subtangle_milestone[30m]) == 0
        and iota_node_info_latest_subtangle_milestone != 243000
      for: 1m
      labels:
        severity: critical
      annotations:
        description: 'Latest Subtangle Milestone increase is {{ $value }}'
        summary: 'Latest Subtangle Milestone not increasing'

The line that denotes the time: ``increase(iota_node_info_latest_subtangle_milestone[30m]) == 0`` -- here you can replace the ``30m`` with any other value in the same format (e.g. ``1h``, ``15m`` etc...)

If any changes to this file, remember to restart prometheus: ``systemctl restart prometheus``


.. _upgradeToFeature:

Upgrading the Playbook to Get the Feature
-----------------------------------------

If you installed the playbook before this feature was release you can still install it.

1. Enter the iri-playbook directory and pull new changes:

.. code:: bash

   cd /opt/iri-playbook && git pull

If this command breaks, it means that you have conflicting changes in one of the configuration files. See :ref:`gitConflicts` on how to apply new changes (or hit me up on slack or github for assitance)

2. WARNING, this will overwrite changes to your monitoring configuration files if you had any manually applied! Run the playbook's monitoring role:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --tags=monitoring_role -e overwrite=true

3. **If** the playbook fails with 401 authorization error (probably when trying to run prometheus grafana datasource), you will have to re-run the command and supply your web-authentication password together with the command:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --tags=monitoring_role -e overwrite=true -e iotapm_nginx_password="mypassword"


.. _configMultipleSSHHost:

Configuring Multiple Nodes for Ansible
======================================

Using the Ansible playbook, it is possible to configure multiple full nodes at once.

How does it work?

Basically, following the manual installation instructions should get you there: :ref:`installation`.

This chapter includes some information on how to prepare your nodes.

Overview
--------
The idea is to clone the iri-playbook repository onto one of the servers/nodes, configure values and run the playbook.

The node from where you run the playbook will SSH connect to the rest of the nodes and configure them. Of course, it will also become a full node by itself.


SSH Access
----------
For simplicity, let's call the node from where you run the playbook the "master node".

In order for this to work, you need to have SSH access to all nodes from the master node. This guide is based on user ``root`` access. There is a possibility to run as a user with privileges and become root, but we will skip this for simplicity.


Assuming you already have SSH access to all the nodes (using password?) let's prepare SSH key authentication which allows you to connect without having to enter a password each time.

Make sure you are root ``whoami``. If not, run ``sudo su -`` to become root.

Create New SSH Key
^^^^^^^^^^^^^^^^^^
Let's create a new SSH key:

.. code:: bash

  ssh-keygen -b 2048 -t rsa

You will be asked to enter the path (allow the default ``/root/.ssh/id_rsa``) and password (for simplicity, just click 'Enter' to use no password).

Output should look similar to this::

  # ssh-keygen -b 2048 -t rsa
  Generating public/private rsa key pair.
  Enter file in which to save the key (/root/.ssh/id_rsa):
  Enter passphrase (empty for no passphrase):
  Enter same passphrase again:
  Your identification has been saved in /root/.ssh/id_rsa.
  Your public key has been saved in /root/.ssh/id_rsa.pub.
  The key fingerprint is:
  SHA256:tCmiLASAsDLPAhH3hcI0s0TKDCXg/QwQukVQZCHL3Ok root@test001
  The key's randomart image is:
  +---[RSA 2048]----+
  |#%/. ..          |
  |@%*=o.           |
  |X*o*.   .        |
  |+*. +  . o       |
  |o.oE.o. S        |
  |.o . . .         |
  |. o              |
  | .               |
  |                 |
  +----[SHA256]-----+

The generated key is the default key to be used by SSH when authenticating to other nodes (``/root/.ssh/id_rsa``).


Copy SSH Key Identity
^^^^^^^^^^^^^^^^^^^^^
Next, we copy the public key to the other nodes:

.. code:: bash

  ssh-copy-id -i /root/.ssh/id_rsa root@other-node-name-or-ip

Given that you have root SSH access to the other nodes, you will be asked to enter a password, and possibly a question about host authenticity.

Output should look like::

  # ssh-copy-id root@other-node-name-or-ip
  /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
  The authenticity of host 'node-name (10.10.1.1)' can't be established.
  ECDSA key fingerprint is SHA256:4QAhCxldhxR2bWes4uSVGl7ZAKiVXqgNT7geWAS043M.
  Are you sure you want to continue connecting (yes/no)? yes
  /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
  /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
  root@other-node-name-or-ip's password:

  Number of key(s) added: 1

  Now try logging into the machine, with:   "ssh 'root@other-node-name-or-ip'"
  and check to make sure that only the key(s) you wanted were added.

Perform the authentication test, e.g ``ssh 'root@other-node-name-or-ip'``. This should work without a password.


Run the ``ssh-copy-id -i /root/.ssh/id_rsa root@other-node-name-or-ip`` for each node you want to configure.


Once this is done you can use Ansible to configure these nodes.


.. _usingNano:

Using Nano to Edit Files
========================

Nano is a linux editor with which you can easily edit files. Of course, this is nothing like a graphical editor (e.g. notepad) but it does its job.

Most Linux experts use ``vi`` or ``vim`` which is much harder for beginners.

First, ensure you have ``nano`` installed:

* On **Ubuntu**: ``apt-get install nano -y``
* On **CentOS**: ``yum install nano -y``

Next, you can use nano to create a new file or edit an existing one. For example, we want to create a new file ``/tmp/test.txt``, we run:

.. code:: bash

  nano /tmp/test.txt

Nano opens the file and we can start writing. Let's add the following lines::

  IRI_NEIGHBORS="tcp://just-testing.com:13000 udp://testing:15600"

Instead of writing this, you can copy paste it. Pasting can be done using right mouse click or **SHIFT-INSERT**.

To save the file you can click **F3** or, to exit and save you can click **CTRL-X**, if any modifications it will ask you if to save the file.


After having saved the file, you can run ``nano /tmp/test.txt`` again in order to edit the existing file.


.. note::

  Please check `Nano's Turorial <https://www.howtogeek.com/howto/42980/the-beginners-guide-to-nano-the-linux-command-line-text-editor/>`_ for more information.

