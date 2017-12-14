.. _appendix:

Appendix
********

This chapter includes additional configuration options and/or general systems configuration.

It is meant for more advanced usage.


Using Fully Qualified Domain Name for my server
===============================================

This requires that you have set up DNS service to point a fully qualified domain name to your server's IP address.

For example, ``x-vps.com`` points to 185.10.48.110 (if you simply ``ping x-vps.com`` you will see the IP address).

Port 80 is used as the default HTTP port while 443 is the default for HTTPS.

|

The automatic installer has configured IOTA Peer Manager and the grafana graphs to serve on ports other than 80.

In this chapter we are going to configure nginx to serve IOTA Peer Manager and Grafana on port 80, while using a fully qualified domain name.


What can be done, if you have a FQDN, is use port 80 for all those services.

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


