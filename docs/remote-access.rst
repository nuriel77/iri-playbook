.. _remote_access:

Full Node Remote Access
***********************

There are basically two ways you can connect to the full node remotely. One is describe here, the other in the 'tunneling' chapter below.

IRI has a command-line argument ("option") ``--remote``. Here's an explanation on what it does:

By default, IRI's API port will listen on the local interface (127.0.0.1). This doesn't allow to connect to it externally.


By using the ``--remote`` option, you cause IRI to listen on the external IP.

This option can be specified in the configuration file:

* on **CentOS** ``/etc/sysconfig/iri``
* on **Ubuntu** ``/etc/default/iri``

Find the line:

.. code:: bash

   OPTIONS=""

and add ``--remote`` to it:

.. code:: bash

   OPTIONS="--remote"

Then restart iri: ``systemctl restart iri``

After IRI initializes, you will see (by issuing ``lsof -Pni|grep java``) that the API port is listening on your external IP.

.. note::

  By default, this installation is set to **not** allow external communication to this port for security reasons.
  Should you want to allow this, you need to allow the port in the firewall.


Expose IRI API Port in Firewall
===============================

In **CentOS**:

.. code:: bash

   firewall-cmd --add-port=14265/tcp --zone=public --permanent && firewall-cmd --reload

In **Ubuntu**:

.. code:: bash

   ufw allow 14265/tcp


Now you should be able to point your (desktop's) light wallet to your server's IP:port (e.g. 80.120.140.100:14265)

More in this chapter:

* `Tunneling IRI API for Wallet Connection`_
* `Peer Manager Behind WebServer with Password`_
* `Limiting Remote Commands`_


.. tunnelingIriApiForWalletConnections::

Tunneling IRI API for Wallet Connection
---------------------------------------

Another option for accessing IRI and/or the iota-pm GUI is to use a SSH tunnel.

SSH tunnel is created within a SSH connection from your computer (desktop/laptop) towards the server.

The benefit here is that you don't have to expose any of the ports or use the ``--remote`` flag. You use SSH to help you tunnel through its connection to the server in order to bind to the ports you need.

.. note::

   For IOTA Peer Manager, this installation has already configured it to be accessible via a webserver.
   See `Peer Manager Behind WebServer with Password`_


What do you need to "forward" the IRI API?

* Your server's IP
* The SSH port (22 by default in which case it doesn't need specifying)
* The port on which IRI API is listening
* The port on which you want to access IRI API on (let's just leave it the same as the one IRI API is listening on)

A default installation would have IRI API listening on TCP port 14265.


.. note::

   In order to create the tunnel you need to run the commands below **from** your laptop/desktop and not on the server where IRI is running.


For Windows desktop/laptop
^^^^^^^^^^^^^^^^^^^^^^^^^^
You can use Putty to create the tunnel/port forward - you can use `this example <http://realprogrammers.com/how_to/set_up_an_ssh_tunnel_with_putty.html>` to get you going, just replace the MySQL 3306 port with that of IRI API.

For any type of bash command line (Mac/Linux/Windows bash)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Here is the tunnel we would have to create (run this on our laptop/desktop)

.. code:: bash

   ssh -p <ssh port> -N -L <iota-pm-port>:localhost:<iota-pm-port> <user-name>@<server-ip>

Which would look like:

.. code:: bash
   
   ssh -p 22 -N -L 14265:localhost:14265 root@<your-server-ip>

Should it ask you for host key verification, reply 'yes'.

Once the command is running you will not see anything, but you can connect with your wallet.
Edit your wallet's "Edit Node Configuration" to point to a custom host and use ``http://localhost:14265`` as address.

To stop the tunnel simply press ``Ctrl-C``.

You can do the same using the IRI API port (14265) and use a light wallet from your desktop to connect to ``http://localhost:14265``.

.. peerManagerBehindWebServerWithPassword::

Peer Manager Behind WebServer with Password
===========================================

This installation also configured a webserver (nginx) to help access IOTA Peer Manager.
It also locks the page using a password, one which you probably configured earlier during the installation steps.

The IOTA Peer Manager can be accessed if you point your browser to: ``http://your-server-ip:8811``.

.. note::

   The port 8811 will be configured by default unless you changed this before the installation in the variables file.

.. limitingRemoteCommands::

Limiting Remote Commands
========================

There's an option in the configuration file which works in conjunction with the ``--remote`` option:

.. code:: bash

   REMOTE_LIMIT_API="removeNeighbors, addNeighbors, interruptAttachingToTangle, attachToTangle, getNeighbors"


On CentOS edit ``/etc/sysconfig/iri``, on Ubuntu ``/etc/default/iri``.

This option excludes the commands in it for the remote connection. This is to protect your node.
If you make changes to this option, you will have to restart IRI (``systemctl restart iri``).
