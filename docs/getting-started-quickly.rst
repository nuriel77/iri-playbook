.. _gettingStartedQuickly:

#######################
Getting Started Quickly
#######################

You can skip most of the information in this tutorial should you wish to do so and go straight ahead to install the full node.

There are just two little things you need to do first:

Once you are logged in to your server, make sure you are root (run ``whoami``).
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

First, let's ensure the installation is running within a "screen" session.
This ensures that the installer stays running in the background if the connection to the server breaks:

.. code:: bash

   screen -S iota


Now we can run the installer:

.. code:: bash

   bash <(curl https://raw.githubusercontent.com/nuriel77/iri-playbook/master/fullnode_install.sh)


.. note::

   If during the installation you are requested to reboot the node, just do so and re-run the command above once the node is back.


That's it. You can proceed to the `Post Installation`_ for additional information on managing your node.


If you lost connection to your server during the installation, don't worry. It is running in the background because we are running it inside a "screen" session
.

You can always "reattach" back that session when you re-connect to your server:

.. code:: bash

   screen -r -d iota



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

