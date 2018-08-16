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

    # Redirect same port from http to https
    # The two lines here under are included in newer
    # versions of the playbook. Omit those if they were
    # not present in your configuration file.
    error_page 497 https://$host:$server_port$request_uri;
    include /etc/nginx/conf.d/ssl.cfg;

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

  For **Ubuntu/Debian** you will have to allow http port in ufw firewall:

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

  Using SSL/HTTPS for accessing your panels ensures all traffic and passwords are impossible to "sniff". The iri-playbook enables HTTPS by default but uses a self-signed certificate.


.. _serverHTTPS:

Configuring my server with HTTPS
================================

There are amazing tutorials out there explaining how to achieve this. What is important to realize is that you can either create your own "self-signed" certificates (you become the Certificate Authority which isn't recognized by anyone else), or use valid certificate authorities.

Since a while the IRI Playbook uses own generated self-signed certificate by default. You can replace the certificate and key with your own certificate+key. This can be done here ``/etc/nginx/conf.d/ssl.cfg`` (this file is included in most configurations).

`Let's Encrypt <https://letsencrypt.org/getting-started/>`_ is a free service which allows you to create a certificate per domain name. Other solution would be to purchase a certificates.

By having a "valid" certificate for your server (signed by a trusted authority), you will get the green lock next to the URL in the browser, indicating that your connection is secure.

Your connection will also be encrypted if you opt for a self-signed certificate. However, the browser cannot verify who signed the certificate and will report a certificate error (in most cases you can just accept it as an exception and proceed).


Here is a great tutorial on how to add HTTPS to your **nginx**, choose nginx and the OS version you are using (Ubuntu/Debian/CentOS):

(For iri-playbook installations you can configure the generated certificate and key in /etc/nginx/conf.d/ssl.cfg)

https://certbot.eff.org/


.. note::

  I encourage you to refer to the previous chapter about configuring FQDN for Peer Manager and Grafana. From there you can proceed to adding HTTPS to those configurations.



.. note::

  For **Ubuntu/Debian** you will have to allow https port in ufw firewall:

  ufw allow https


  For **Centos**:

  firewall-cmd --add-service=https --permanent --zone=public && firewall-cmd --reload


.. _revProxyWallet:

Reverse Proxy for IRI API (wallet)
==================================

If you read the two chapters above about configuring nginx to support FQDN or HTTPS you might be wondering whether you should reverse proxy from the web server to IRI API port (for wallet connections etc).

``iri-playbook`` installs HAProxy with which you can reverse proxy to IRI API port and benefit from logging and security policies. In addition, you can add a HTTPS certificate. IOTA's Trinity wallet requires nodes to have a valid SSL certificate.

See :ref:`haproxyEnable` on how to enable HAproxy for wallet via reverse proxy and how to enable HTTPS(SSL) for it.



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

* On **Ubuntu/Debian**: ``apt-get install nano -y``
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

.. _haproxyEnable:

Running IRI API Port Behind HAProxy
===================================

The IRI API port can be configured to be accessible via HAProxy. The benefits in doing so are:

- Logging
- Whitelist/blacklisting
- Password protection
- Rate limiting per IP, or per command
- Denying invalid requests

To get it configured and installed you can use ``iric`` or run::

  cd /opt/iri-playbook && git pull && ansible-playbook -i inventory -v site.yml --tags=iri_ssl,loadbalancer_role -e lb_bind_address=0.0.0.0 -e overwrite=yes


Please read this **important information**:

The API port will be accessible on **14267** by default.

**Note** that if you have previously enabled IRI with ``--remote`` option or ``API_HOST = 0.0.0.0`` you can disable those now. HAProxy will take care of that.

In addition, the **REMOTE_LIMIT_API** in the configuration files are no longer playing any role. HAProxy has taken control over the limited commands.

To see the configured denied/limited commands see ``group_vars/all/lb.yml`` or edit ``/etc/haproxy/haroxy.cfg`` after installation. The regex is different from what you have been used to.


.. _rateLimits:

Rate Limits
-----------

HAProxy enables rate limiting. In some cases, if you are loading a seed which has a lot of transactions on it, HAProxy might block too many requests.

One solution is to increase the rate limiting values in ``/etc/haproxy/haproxy.cfg``. Find those lines and set the number accordingly:

.. code:: bash

  # dynamic stuff for frontend + raise gpc0 counter
  tcp-request content  track-sc2 src
  acl conn_rate_abuse  sc2_conn_rate gt 250
  acl http_rate_abuse  sc2_http_req_rate gt 400
  acl conn_cur_abuse  sc2_conn_cur gt 21


Don't forget to restart HAProxy afterwards: ``systemctl restart haproxy``.



.. _enableHTTPSHaproxy:

Enabling HTTPS for HAProxy
--------------------------

To enable HTTPS for haproxy run the following command or find the option in the main menu of ``iric``. It will enable HAProxy to serve the IRI API on port 14267 with HTTPS (Warning: this will override any manual changes you might have applied to ``/etc/haproxy/haproxy.cfg`` previously):

.. code:: bash

  cd /opt/iri-playbook && git pull && ansible-playbook -i inventory site.yml -v --tags=iri_ssl,loadbalancer_role -e lb_bind_address=0.0.0.0 -e haproxy_https=yes -e overwrite=yes

Note that this will apply a default self-signed certificate, but the command is required to enable HTTPS in the first place. If you want to use a valid certificate from a trusted certificate authority you can provide your own certificate + key file manually after running the above command. Alternatively, check the section below for installing a Let's Encrypt certificate which is free:

**Let's Encrypt Free Certificate** You can install a ``letsencrypt`` certificate: one prerequisite is that you have a fully qualified domain name pointing to the IP of your node.

If you already have a domain name, and ran the above command to enable HTTPS, you can run the following script::

  /usr/local/bin/certbot-haproxy.sh

The script will ask you for your email address which is used as an account at Let's Encrypt. It will also ask for the domain name that points to your server's public IP address.

The script will install the required utilities and request the certificate for you. It will proceed to install the certificate with HAProxy and add a cron job to automatically renew the certificate before it expires.

Once the script is finished you can point your browser to ``https://your-domain-name:14267``: you should get a 403 forbidden page. You will be able to see the green lock icon/pad on the left of the URL which means the certificate is valid.


If you need help with this, please find help on Discord #fullnodes channel.

.. note::

  This setup is not fully automated yet via ``iric``. For that reason, please avoid running the HAProxy enable commands as that will overwrite the certificate configuration in haproxy configuration file. If you did that accidentally you can always run the ``/usr/local/bin/certbot-haproxy.sh`` once more and it will set the correct configuration file for haproxy.

.. note::

  If you previously used a script to configure Let's Encrypt with Nginx and your Nginx is no longer working, please follow the instructions at :ref:`fixNginx`



.. _options:

Installation Options
====================

This is an explanation about the select-options provided by the fully automated installer.

Docker
------
This installation runs all the services inside Docker containers. If you already have Docker installed on your system you might choose to skip this step.

Nginx
-----
Nginx is a fast and versatile webserver. Its main function in this configuration is to allow access to GUIs in the browser such as IOTA Peer Manager, Prometheus, Grafana and more.

System Dependencies
-------------------
Although all services are going to run inside of Docker, some additional packages installed on the system are required. If you choose not to install any dependencies, some things might not function as expected and you will have to resolved the dependencies manually.

Firewall
--------
The installation takes care of the firewalls: it ensures the firewall is running and configures the required ports. You can choose not to let the installer configure the firewall should you wish to do this manually.

Nelson
------
Nelson is a software which enabled auto-peering for IRI (finding neighbors automatically).

If Nelson is not used, neighbors have to be manually maintained (default).

You can read more about it `here <https://github.com/SemkoDev/nelson.cli>`_.

Field
-----
Field is a proxy for your IRI node that sends regular statistics to the `Field server <http://field.deviota.com>`_.

You can read more about it `here <https://github.com/SemkoDev/field.cli>`_.

In addition to field, field-exporter is installed which provides metrics about the node's performance in the Field and other stats from the Field server.

You can read more about it `here <https://github.com/DaveRingelnatz/field_exporter>`_.

HAproxy
-------
HAProxy is a proxy/load-balancer. In the context of this installation it can be enabled to serve the IRI API port.

You can read more about it here: :ref:`haproxyEnable`.

Monitoring
----------
The monitoring refers to installation of:

- Prometheus (metrics collector)
- Alertmanager (trigger alerts based on certain rules)
- Grafana (Metrics dashboard)
- Iota-prom-exporter (IRI full node metrics exporter for Prometheus)

It is recommended to install those to have a full overview of your node's performance.

ZMQ Metrics
-----------
IRI can provide internal metrics and data by exposing ZeroMQ port (locally by default). If enabled, this will allow the iota-prom-exporter to read this data and create additional graphs in Grafana (e.g. transactions confirmation rate etc).


.. _upgradeIri:

Upgrade IRI and Remove Existing Database
========================================

(option #3 from the `IOTA Snapshot Blog <https://blog.iota.org/the-april-29-2018-iota-snapshot-and-iri-1-4-2-4-behind-the-scenes-7e034babcd44>`_)

A snapshot of the database normally involves a new version of IRI. This is also the case in the upcoming snapshot of April 29th, 2018.

Here are the steps you should follow in order to get a new version of IRI and remove the old database:

Run the following commands as user ``root`` (you can run ``sudo su`` to become user root).

1. Stop IRI:

.. code:: bash

  systemctl stop iri

2. Remove the existing database:

.. code:: bash

  rm -rf /var/lib/iri/target/mainnet*

3. Run ``iric`` the command-line utility. Choose "Update IRI Software". This will download the latest version and restart IRI.

If you don't have ``iric`` installed, you can refer to this chapter on how to upgrade IRI manually :ref:`upgradeIri`.


.. _upgradeIriKeepDB:

Upgrade IRI and Keep Existing Database
======================================

(option #2 from the `IOTA Snapshot Blog <https://blog.iota.org/the-april-29-2018-iota-snapshot-and-iri-1-4-2-4-behind-the-scenes-7e034babcd44>`_)

If you want to keep the existing database, the instructions provided by the IF include steps to compile the RC version (v1.4.2.4_RC) and apply a database migration tool.


To make this process easy, I included a script that will automate this process. This script works for both CentOS and Ubuntu/Debian (but **only** for ``iri-playbook`` installations).

You will be asked if you want to download a pre-compiled IRI from my server, or compile it on your server should you choose to do so.


Please read the warning below and use the following command (as root) in order to upgrade to 1.4.2.4_RC and keep the existing database:

.. code:: bash

  bash <(curl -s https://x-vps.com/get_iri_rc.sh)


.. warning::

  This script will only work with installations of the iri-playbook.
  I provide this script to assist, but I do not take any responsibility for any damages, loss of data or breakage.
  By running this command you agree to the above and you take full responsibility.


For assistance and questions you can find help on IOTA's #fullnodes channel (discord).
