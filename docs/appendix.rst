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



Sending Alert Notifications
===========================

Since release v1.1 a new feature has been introduced to support alerting.

.. warning::

   This is considered an advanced feature. Configuration hereof requires some basic Linux and system configuration experience.



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

4. Save the file (in nano CTRL-X and confirm 'y')

5. Restart alertmanager: ``systemctl restart alertmanager``


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
