.. _requirements:

The Requirements
================

* `Virtual Private Server`_
* `Operating System`_
* `Accessing the VPS`_

.. _virtualPrivateServer:

Virtual Private Server
----------------------

Having a Virtual Private Server (VPS) at a hosting company is probably the best and most common option for running a full node.

There are many companies offering a VPS for good prices. Make sure not to take a VPS platform which is based on Virtuozzo or OpenVZ. Performance is not best and I personally don't like the fact the hosting company can see what processes I am running on my private server.

Also, a good advice is not to take a contract for a year, but try to find hosting service with pay-per-hour or monthly contract. Be aware that some VPS hosting such as SSDNodes had reports by fullnode operators that their contracts have been suspended due to running "crypto" software (IRI).

The minimum recommendation is to have a node with at least 4GB RAM, 2 cores and minimum 60GB harddrive (SSD preferably).

For better performance, at least 6GB RAM and 4 cores are necessary (for example when running consul and consul-haproxy-template for load balancing)

.. _operatingSystem:

Operating System
----------------
When you purchase a VPS you are often given the option which operating system (Linux of course) and which distribution to install on it.

The installer was tested on Ubuntu (LTS only), CentOS and Debian versions:

* `Ubuntu 16.04 (amd64) Server Cloud Image (Xenial) <https://cloud-images.ubuntu.com/xenial/current/>`_
* `Ubuntu 17.04 (amd64) Server Cloud Image (Zesty) <https://cloud-images.ubuntu.com/zesty/current/>`_
* `Ubuntu 18.04 (amd64) Server Cloud Image (Bionic) <https://cloud-images.ubuntu.com/bionic/current/>`_
* `Ubuntu 16.04, 17.10 and 18.04 (amd64) Server image ISO <https://www.ubuntu.com/download/server>`_
* `Debian 9.5 x86_64 image for OpenStack <http://cdimage.debian.org/cdimage/openstack/current-9>`_
* `CentOS 7.4 x86_64 Generic Cloud Image <http://cloud.centos.org/centos/7/images/>`_ or `CentOS Minimal ISO <http://isoredirect.centos.org/centos/7/isos/x86_64/>`_

As mentioned above only LTS versions of Ubuntu are supported (e.g. 18.04 and not 18.10)

.. note::

  This installation does not support operating systems with pre-installed panels such as cpanel, whcms, plesk etc. If you can, choose a "bare" system.

.. warning::

   Some VPS providers provide a custom OS installation (Ubuntu, Debian or CentOS) with additional software installed (LAMP, cpanel etc).
   These images will not work nicely with the installer.
   In some cases, VPS providers modify images and might deliver operating systems that will be incompatible with this installer.


.. _accessingTheVPS:

Accessing the VPS
-----------------
Once you have your VPS deployed, most VPS hosting provide a terminal (either GUI application or web-based terminal). Using the terminal you can login to your VPS's
command line.

You most probably received a password with which you can login to the server. This can be a 'root' password, or a 'privileged' user (with which you can access 'root' privileges).

The best way to access the server is via a Secure Shell (SSH).

If your desktop is Mac or Linux, this is native on the command line. If you use Windows, I recommend installing `Putty <https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html>`_

There are plenty of tutorials on the web explaining how to use SSH (or SSH via Putty). Basically, you can use a password login or SSH keys (better).
