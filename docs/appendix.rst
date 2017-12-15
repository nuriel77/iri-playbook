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


