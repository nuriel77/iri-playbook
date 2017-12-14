.. _requirements:

The Requirements
================

* `Virtual Private Server`_
* `Operating System`_
* `Accessing the VPS`_
* `System User`_


.. _virtualPrivateServer:

Virtual Private Server
----------------------

This is probably the best and most common option for running a full node.

I will not get into where or how to purchase a VPS (virtual private server). There are many companies offering a VPS for good prices.

The basic recommendation is to have one with at least 4GB RAM, 2 cores and minimum 30GB harddrive (SSD preferably).

.. note::

   At time of writing (December 2018) many users are experiencing out-of-memory errors with 4GB RAM. This should be remedied by next snapshot.


.. _operatingSystem:

Operating System
----------------
When you purchase a VPS you are often given the option which operating system (Linux of course) and which distribution to install on it.

This tutorial/installer was tested on:

* Ubuntu 16.04 cloud image (Xenial)
* Ubuntu 17.04 cloud image (Zesty)
* CentOS 7.4 cloud image

.. note::

  This installation does not support operating systems with pre-installed panels such as cpane, whcms, plesk etc. If you can, choose a "bare" system.

.. warning::

   Some VPS providers provide a custom OS installation (Ubuntu or CentOS) with additional software installed (cpanel etc).
   These images will not work nicely with the installer.
   In some cases, VPS providers modify images and might deliver operating systems that will be incompatible with this installer.


.. _accessingTheVPS:

Accessing the VPS
-----------------
Once you have your VPS deployed, most hosting provide a terminal (either GUI application or web-based terminal). With the terminal you can login to your VPS's
command line.
You probably received a password with which you can login to the server. This can be a 'root' password, or a 'privileged' user (with which you can access 'root
' privileges).

The best way to access the server is via a Secure Shell (SSH).
If your desktop is Mac or Linux, this is native on the command line. If you use Windows, I recommend installing `Putty <https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html>`_

There are plenty of tutorials on the web explaining how to use SSH (or SSH via Putty). Basically, you can use a password login or SSH keys (better).


.. _systemUser:

System User
-----------
Given you are the owner of the server, you should either have direct access to the 'root' account or to a user which is privileged.
It is often recommended to run all commands as the privileges user, prefixing the commands with 'sudo'. In this tutorial I will leave it to the user to decide.


If you accessed the server as a privileged user, and want to become 'root', you can issue a ``sudo su -``.
Otherwise, you will have to prefix most commands with ``sudo``, e.g.

.. code-block:: bash

   sudo apt-get install something

