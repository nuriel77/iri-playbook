.. _faq:

FAQ
***

* `How to tell if my node is synced`_
* `Why do I see the Latest Milestone as 243000`_
* `How do I tell if I am syncing with my neighbors`_
* `Why is latestSolidSubtangleMilestoneIndex always behind latestMilestoneIndex`_
* `How to get my node swap less`_
* `What are the revalidate and rescan options for`_
* `Where can I get a fully synced database to help kick start my node`_
* `I try to connect the light wallet to my node but get connection refused`_

.. howToTellNodeSynced::

How to tell if my node is synced
================================

You can check that looking at iota-pm GUI.
Check if ``Latest Mile Stone Index`` and ``Latest Solid Mile Stone Index`` are equal:

.. image:: https://x-vps.com/static/images/synced_milestones.png
   :alt: synced_milestone

Another option is to run the following command on the server's command line (make sure the port matches your IRI API port)::

  curl -s http://localhost:14265   -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json'   -d '{"command": "getNodeInfo"}'| jq '.latestSolidSubtangleMilestoneIndex, .latestMilestoneIndex'

This will output 2 numbers which should be equal.

.. note::

    Above command will fail if you don't have ``jq`` installed. See below how to install it.

You can install ``jq``:

**Ubuntu**: ``apt-get install jq -y``

**Centos**: ``yum install jq -y``

Alternatively, use python::

  curl -s http://localhost:14265   -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json'   -d '{"command": "getNodeInfo"}'|python -m json.tool|egrep "latestSolidSubtangleMilestoneIndex|latestMilestoneIndex"


.. whyDoIseeLatestMileStoneLow::

Why do I see the Latest Milestone as 243000
===========================================
This is expected behavior of you restarted IRI recently.
Depending on various factors, it might take up to 30 minutes for this number to clear and the mile stones start increasing.


.. howDoITellIfIamSyncing::

How do I tell if I am syncing with my neighbors
===============================================
You can use IOTA Peer Manager. Have a look at the neighbors boxes. They normally turn red after a while if there's no sync between you and their node.
Here's an example of a healthy neighbor, you can see it is also sending new transactions (green line) and the value of New Transactions increases in time:

.. image:: https://x-vps.com/static/images/healthy_neighbor.png
   :alt: health_neighbor

|

.. whyIsLSMAlwaysBehind::

Why is latestSolidSubtangleMilestoneIndex always behind latestMilestoneIndex
============================================================================
This is probably the most frequently asked question.

At time of writing, and to the best of my knowledge, there is not one definitive answer. There are probably various factors that might keep the Solid milestone from ever reaching the latest one and thus remaining not fully synced.

I have noticed that this problem exacerbates when the database is relatively large (5GB+). This is mostly never a problem right after a snapshot, when things run much smoother. This might also be related to ongoing "bad" spam attacks directed against the network.

What helped my node to sync was:

* `How to get my node swap less`_
* `Where can I get a fully synced database to help kick start my node`_
* Finding "healthier" neighbors. This one is actually often hard to ascertain -- who is "healthy", probably other fully synced nodes.


.. nodeSwapLess::

How to get my node swap less
============================
You can always completely turn off swap, which is not always the best solution. Using less swap (max 1GB) can be helpful at times to avoid some OOM killers (out-of-memory).

As a simple solution you can change the "swappiness" of your linux system.
I have a 8GB 4 core VPS, I lowered the swappiness down to 1. You can start with a value of 10, or 5.
Run these two commands::

  echo "vm.swappiness = 1" >>/etc/sysctl.conf

and::

  sysctl -p


You might need to restart IRI in order for it to adapt to the new setting.
Try to monitor the memory usage using ``free -m``, swap in particular, e.g.::

  free -m
                total        used        free      shared  buff/cache   available
  Mem:           7822        3331         692         117        3798        4030
  Swap:          3815           1        3814

You'll see that in this example nothing is being used.
If a large "used" value appears for Swap, it might be a good idea to lower the value and restart IRI.


.. revalidateExplain::

What are the revalidate and rescan options for
==============================================

Here's a brief explanation what each does, courtesy of Alon Elmaliah:

| **Revalidate** "drops" the stored solid milestone "table". So all the milestones are revalidated once the node starts (checks signatures, balances etc). This is used it you take a DB from someone else, or have an issue with solid milestones acting out.

| **Rescan** drops all the tables, except for the raw transaction trits, and re stores the transactions (refilling the metadata, address indexes etc) - this is used when a migration is needed when the DB schema changes mostly.



It is possible to add these options to the IRI configuration file (or startup command):

``--revalidate`` or ``--rescan``.

If you have used this installation's tutorial / automation, you will find the configuration file in the following location::

  On Ubuntu: /etc/default/iri
  On CentOS: /etc/sysconfig/iri

You will see the OPTIONS variable, so you can tweak it like so::

  OPTIONS="--rescan"

and restart IRI to take effect: ``systemctl restart iri``

.. note::

  Once you've restarted the service with the ``--rescan`` or ``--revalidate`` options you can remove the option from the configuration file.
  If it stays in the configuration file, subsequent restarts will use that option again, perhaps when you do not explicitly choose to enable it.


.. getFullySyncedDB::

Where can I get a fully synced database to help kick start my node
==================================================================

There's a public node that makes a copy of the database once every hour.

https://iota.lukaseder.de/download.html

Please consider donating them some iotas for the costs involved in making this possible.

1. You can download the database using the following command:

.. code:: bash

  cd /var/lib/iri/target && curl --output db.tar.gz https://iota.lukaseder.de/downloads/db.tar.gz


2. Unpack it:

.. code:: bash

   mkdir -p db && pv db.tar.gz | tar xzf - -C db

3. Stop iri if its running:

.. code:: bash

   systemctl stop iri

4. Remove older database:

.. code:: bash

   rm -rf /var/lib/iri/target/mainnet*

5. Move new database to required location:

.. code:: bash

   mv db/ mainnetdb

6. Delete the lock file:

.. code:: bash

   rm -f mainnetdb/LOCK

7. Set correct ownership of database:

.. code:: bash

   chown iri.iri mainnetdb -R

8. Start iri:

.. code:: bash

   systemctl start iri


.. note::

  There was some debate on the slack channel whether after having imported a foreign database if it is required to run IRI with the ``--revalidate`` or ``--rescan`` flags. Some said they got fully synced without any of these.

To shed some light on what these options actually do, you can read about it in `What are the revalidate and rescan options for`_

.. lightWalletConnectionRefused::

I try to connect the light wallet to my node but get connection refused
=======================================================================
There are commonly two reasons for this to happen:

If your full node is on a different machine from where the light wallet is running from, there might be a firewall between, or, your full node is not configured to accept external connections.

See :ref:`remote_access`

