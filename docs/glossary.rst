.. _glossary:

Command Glossary
****************
This is a collection of most command commands to come in handy.

Check IRI's node status
=======================

.. code:: bash

   curl -s http://localhost:14265 -X POST -H 'X-IOTA-API-Version: someval' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}' | jq

Same as above but extract the milestones

.. code:: bash

   curl -s http://localhost:14265   -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json'   -d '{"command": "getNodeInfo"}'|python -m json.tool|egrep "latestSolidSubtangleMilestoneIndex|latestMilestoneIndex"


Add neighbors
=============

This is the nbctl script that shipped with this installation (use it with -h to get help):

.. code:: bash

   nbctl -a -n udp://1.2.3.4:12345 -n tcp://4.3.2.1:4321


Remove neighbors
================

This is the nbctl script that shipped with this installation (use it with -h to get help):

.. code:: bash

   nbctl -r -n udp://1.2.3.4:12345 -n tcp://4.3.2.1:4321


Check iri and iota-pm ports listening
======================================

.. code:: bash

   lsof -Pni|egrep "iri|iotapm"


Check all ports on the node
===========================

.. code:: bash

   lsof -Pni


Opening a port in the firewall
==============================

In **CentOS**::

  firewall-cmd --add-port=14265/tcp --zone=public --permanent && firewall-cmd --reload

In **Ubuntu**::

  ufw allow 14265/tcp


Checking memory usage per application
=====================================

This is the ps_mem script that shipped with this installation. If you don't have it you can see total memory usage using ``free -m``.

.. code:: bash

   ps_mem


Checking system load and memory usage
=====================================

All Linux systems have ``top``, but there's a nicer utility called ``htop``.

You might need to install it:

.. code:: bash

   On Ubuntu: apt-get install htop -y
   On CentOS: yum install htop -y


Then run ``htop``

.. note::

  If 'htop' is not available in CentOS you need to install 'epel-release' and try again, i.e. 'yum install epel-release -y'



