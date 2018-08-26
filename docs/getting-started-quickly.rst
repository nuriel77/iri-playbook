.. _getting_started_quickly:

#######################
Getting Started Quickly
#######################

You can skip most of the information in this tutorial should you wish to do so and go straight ahead to install the full node.

If you haven't already, just make sure your server matches the :ref:`requirements`.


.. warning::

   Your server's installation of Ubuntu or CentOS must be a clean one, i.e. no pre-installed cpanel, whcms, plesk and so on.
   This installer might BREAK any previously installed web-server. It is meant to be installed on a clean system!


Run the Installer!
==================

For **CentOS** users: you may need to install ``curl``. You can do that by running: ``sudo yum install curl -y``.

For **Ubuntu/Debian** if ``curl`` isi missing you can install it by running: ``sudo apt-get install curl -y``.

|

**The installation command will pull a script and kick off the installation. Make sure you read the warning above!**

Original IRI Playbook
---------------------

To install the original playbook version:

.. code:: bash

   bash <(curl -s https://raw.githubusercontent.com/nuriel77/iri-playbook/master/fullnode_install.sh)

Dockerized IRI Playbook (beta)
------------------------------

For the "Dockerized" version (containers) run:

.. code:: bash

  GIT_OPTIONS="-b feat/docker" bash <(curl -s https://raw.githubusercontent.com/nuriel77/iri-playbook/feat/docker/fullnode_install.sh)

Documentation for the "Dockerized" version can be `found here <https://iri-playbook.readthedocs.io/en/feat-docker/>`_.


Additional Information
----------------------

* If during the installation you are requested to reboot the node, just do so and re-run the commands above once the node is back.

* A successful installation will display some information when it is done, e.g. the URLs where you can access the graphs and IOTA Peer Manager.

By default you can access the graphs at::

  http://your-ip:5555/dashboard/db/iota?refresh=30s&orgId=1

and Peer Manager via::

  http://your-ip:8811

* You can use the user ``iotapm`` and the password you've configured during the installation.

* You should be redirected to a HTTPS URL (this has been added recently). This is a self-signed certificate: you will get a warning from the browser. You can add the certificate as an exception and proceed. In the 'appendix' chapter there's some information how to install valid certificates (certbot).

* Please consider hardening the security of your node. Any server is a target for attacks/brute forcing. Even more so if you are going to list your node publicly. See :ref:`securityHardening`.

* You can proceed to the :ref:`post_installation` for additional information on managing your node.

* To configure an email for alerts see :ref:`alerting`.

* Visit the project's page at the `IOTA Ecosystem <https://ecosystem.iota.org/projects/iri-fullnode-installer>`_

.. note::

  Checkout the new addition to the playbook: a handy tool to help manage the full node's services:

.. image:: https://raw.githubusercontent.com/nuriel77/iri-playbook/master/docs/images/iric_01.png
            :alt: iric01

Connection Lost
---------------

If you lost connection to your server during the installation, don't worry. It is running in the background because we are running it inside a "screen" session
.

You can always "reattach" back that session when you re-connect to your server:

.. code:: bash

   screen -r -d iota


.. note::

  Pressing arrow up on the keyboard will scroll up the command history you've been running. This saves some typing when you need to run the same command again!

.. warning::

  Some VPS providers might be depending on Network Block Devices (for example Scaleway). If using Ubuntu, you need to configure ufw prior to running the installer.
  See: https://gist.github.com/georgkreimer/7a02af49604da91c5e3605b08b2872ec



Accessing Peer Manager
----------------------
You can access the peer manager using the user 'iotapm' and the password you've configured during installation:

.. code:: bash

  http://your-ip:8811


Accessing Monitoring Graphs
---------------------------
You can access the Grafana IOTA graphs using 'iotapm' and the password you've configured during the installaton

.. code:: bash

  http://your-ip:5555


Big thanks to Chris Holliday's amazing tool for `node monitoring <https://github.com/crholliday/iota-prom-exporter>`_

