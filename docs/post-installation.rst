.. _post_installation:

Post Installation
*****************

We can run a few checks to verify everything is running as expected.
First, let's use the ``systemctl`` utility to check status of iri (this is the main full node application)

Using the ``systemctl status iri`` we can see if the process is ``Active: active (running)``.

See examples in the chapters below:

* `Controlling IRI`_
* `Controlling IOTA Peer Manager`_
* `Checking Ports`_
* `Checking IRI Full Node Status`_
* `Connecting to IOTA Peer Manager`_
* `Adding or Removing Neighbors`_
* `Install IOTA Python libs`_


.. note::

  See :ref:`maintenance` for additional information, for example checking logs and so on.
  Also, you can refer to :ref:`glossary` for a quick over view of most common commands.


.. controlingIRI::

Controlling IRI
===============
Check status:

.. code:: bash

   systemctl status iri


Stop:

.. code:: bash

   systemctl stop iri


Start:

.. code:: bash

   systemctl start iri


Restart:

.. code:: bash

   systemctl restart iri


.. controlingPM::

Controlling IOTA Peer Manager
=============================

Check status:

.. code:: bash

   systemctl status iota-pm


Stop:

.. code:: bash

   systemctl stop iota-pm


Start:

.. code:: bash

   systemctl start iota-pm


Restart:

.. code:: bash

   systemctl restart iota-pm


.. checkPorts::

Checking Ports
==============

IRI uses 3 ports by default:

1. UDP neighbor peering port
2. TCP neighbor peering port
3. TCP API port (this is where a light wallet would connect to or iota peer manageR)

You can check if IRI and iota-pm are "listening" on the ports if you run:

``lsof -Pni|egrep "iri|iotapm"``.

Here is the output you should expect::

  # lsof -Pni|egrep "iri|iotapm"
  java     2297    iri   19u  IPv6  20331      0t0  UDP *:14600
  java     2297    iri   21u  IPv6  20334      0t0  TCP *:14600 (LISTEN)
  java     2297    iri   32u  IPv6  20345      0t0  TCP 127.0.0.1:14265 (LISTEN)
  node     2359 iotapm   12u  IPv4  21189      0t0  TCP 127.0.0.1:8011 (LISTEN)


What does this tell us?

1. ``*:<port number>`` means this port is listening on all interfaces - from the example above we see that IRI is listening on ports TCP and UDP no. 14600
2. IRI is listening for API (or wallet connections) on a local interface (not accessible from "outside") no. 14265
3. Iota-PM is listening on local interface port no. 8011

Now we can tell new neighbors to connect to our IP address.



Here's how to check your IP address:

If you have a static IP - which a VPS most probably has - you can view it by issuing a ``ip a``.
For example::

  ip a
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8950 qdisc pfifo_fast state UP qlen 1000
      link/ether fa:16:3e:d6:6e:15 brd ff:ff:ff:ff:ff:ff
      inet 10.50.0.24/24 brd 10.50.0.255 scope global dynamic eth0
         valid_lft 83852sec preferred_lft 83852sec
      inet6 fe80::c5f4:d95b:ba52:865c/64 scope link
         valid_lft forever preferred_lft forever

See the IP address on ``eth0``? (10.50.0.24) this is the IP address of the server.

**Yes** - for those of you who've noticed, this example is a **private** address. But if you have a VPS you should have a public IP.

I could tell neighbors to connect to my UDP port: ``udp://10.50.0.14:14600`` or to my TCP port: ``tcp://10.50.0.14:14600``.

Note that the playbook installation automatically configured the firewall to allow connections to these ports. If you happen to change those, you will have to
allow the new ports in the firewall (if you choose to do so, check google for iptables or firewalld commands).


.. checkFullNode::

Checking IRI Full Node Status
=============================
The tool ``curl`` can issue commands to the IRI API.

For example, we can run:

.. code:: bash

   curl -s http://localhost:14265 -X POST -H 'X-IOTA-API-Version: someval' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}' | jq

The output you will see is JSON format.
Using ``jq`` we can, for example, extract the fields of interest:

.. code:: bash
   curl -s http://localhost:14265 -X POST -H 'X-IOTA-API-Version: someval' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}' | jq '.latestSolidSubtangleMilestoneIndex, .latestMilestoneIndex'


.. note::

  If you've just started up your IRI node (or restarted) you will see a matching low number for both ``latestSolidSubtangleMilestoneIndex`` and ``latestMilestoneIndex``.
  This is expected, and after a while (10-15 minutes) your node should start syncing (given that you have neighbors).


.. connectPeerManager::

Connecting to IOTA Peer Manager
===============================

For IOTA Peer Manager, this installation has already configured it to be accessible via a webserver. See `Peer Manager Behind WebServer with Password`_.


.. addRemoveNeighbors::

Adding or Removing Neighbors
============================
In order to add neighbors you can either use the iota Peer Manager or do that on the command-line.

To use the command line you can use a script that was shipped with this installation, e.g:

.. code:: bash

   nbctl -a -n udp://1.2.3.4:12345 -n tcp://4.3.2.1:4321

The script will default to connect to IRI API on ``http://localhost:14265``.
If you need to connect to a different endpoint you can provide it via ``-i http://my-node-address:port``.

If you don't have this helper script you will need to run a ``curl`` command, e.g. to add:

.. code:: bash

   curl -H 'X-IOTA-API-VERSION: 1.4' -d '{"command":"addNeighbors",
     "uris":["udp://neighbor-ip:port", "udp://neighbor-ip:port"]}' http://localhost:14265

to remove:

.. code:: bash

   curl -H 'X-IOTA-API-VERSION: 1.4' -d '{"command":"removeNeighbors",
     "uris":["udp://neighbor-ip:port", "udp://neighbor-ip:port"]}' http://localhost:14265



.. note::

   Adding or remove neighbors is done "on the fly", so you will also have to add (or remove) the neighbor(s) in the configuration file of IRI.

The reason to add it to the configuration file is that after a restart of IRI, any neighbors added with the peer manager will be gone.

In CentOS you can add neighbors to the file:

.. code:: bash

   /etc/sysconfig/iri

In Ubuntu:

.. code:: bash

   /etc/default/iri

Edit the ``IRI_NEIGHBORS=""`` value as shown in the comment in the file.


.. installPyota::

Install IOTA Python libs
========================
You can install the official iota.libs.py to use for various python scripting with IOTA and the iota-cli.

On **Ubuntu**:

.. code:: bash

   apt-get install python-pip -y && pip install --upgrade pip && pip install pyota

You can test with the script that shipped with this installation (to reattach pending transactions):

.. code:: bash

   reattach -h


On **CentOS** this is a little more complicated, and better install pyota in a "virtualenv"::

  cd ~
  yum install python-pip gcc python-devel -y
  virtualenv venv
  source ~/venv/bin/activate
  pip install pip --upgrade
  pip install pyota

Now you can test by running the reattach script as shown above. 

.. note::

   Note that if you log in back to your node you will have to run the ``source ~/venv/bin/activate`` to switch to the new python virtual environment.

