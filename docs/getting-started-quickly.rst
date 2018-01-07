.. _getting_started_quickly:

#######################
Getting Started Quickly
#######################

You can skip most of the information in this tutorial should you wish to do so and go straight ahead to install the full node.

If you haven't already, just make sure your server matches the :ref:`requirements`.


A few setup steps are required before you can run the click'n'go installation command:

When you are logged in to your server, make sure you are root (run ``whoami``).
If that is not the case run ``sudo su -`` to become root and enter the password if you are required to do so.


For **CentOS** you might need to install ``curl`` and ``screen`` before you can proceed:

.. code:: bash

   yum install curl screen -y


If you are missing these utilities on **Ubuntu** you can install them:


.. code:: bash

  apt-get install curl screen -y


.. note:

   your server's installation of Ubuntu or CentOS must be a "clean" one -- no pre-installed cpanel, whcms, plesk and so on.



Run the Installer!
==================

1. This installation requires to be run as user ``root``. Make sure you are already root by running ``whoami``. If that is not the case, you can become root using:

.. code:: bash

   sudo su


2. Let's ensure the installation is running within a "screen" session. This ensures that the installer stays running in the background if the connection to the server breaks:

.. code:: bash

   screen -S iota


3. Finally, we can run the installer:

.. code:: bash

   bash <(curl -s https://raw.githubusercontent.com/nuriel77/iri-playbook/master/fullnode_install.sh)


.. note::

   If during the installation you are requested to reboot the node, just do so and re-run the commands above once the node is back.


That's it. You can proceed to the :ref:`post_installation` for additional information on managing your node.

A successful installation will display some information when it is done, e.g. the URLs where you can access the graphs and IOTA Peer Manager.

By default you can access the grpahs at::

  http://your-ip:5555/dashboard/db/iota?refresh=30s&orgId=1

and Peer Manager via::

  http://your-ip:8811

You can use the user ``iotapm`` and the password you've configured during the installation.


If you liked this tutorial, and would like to leave a donation you can use this IOTA address::

  LDWOMAW9IBFEPQ9DRMCIOLLOLVCWGT9OISWNXVQTXPQANRJNDRLNWZVITVBYLMVFSQQFNZXHXQYWLWHEXKWROI9FMZ

Thanks!



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

