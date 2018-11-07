.. _faq:

FAQ
***

.. _overrideFile:

How to override playbook variables
==================================

You might have noticed that many Ansible commands in the documentation use ``-e somevar=value`` to specify variables.

This variable declaration takes precedence over any other pre-defined variables.

An easy approach to override variables in the files found in ``group_vars/all/`` path is to override them.

The reason is that if you edit any of these files you risk a conflict when updates are pulled from the iri-playbook repository.

Overriding file variables
-------------------------
The files in ``group_vars/all/`` are read in alphabetic order.

For example: you have a file called ``aaa.yaml`` with the variable ``test_var``::

  test_var: 1234

and you have a file called ``bbb.yaml``, also with the variable ``test_var``::

  test_var: abcd

When the playbook runs, it first reads the file ``aaa.yaml`` and then ``bbb.yaml``. ``test_var`` ends up with the value ``abcd``.

Best practice is to create a file starting with the letter ``z``, for example ``zzz-myenvironment.yaml`` and in it define all the variables you want.




How to tell if my node is synced
================================

You can check if your node is synced by looking at iota-pm GUI.
Check if ``Latest Mile Stone Index`` and ``Latest Solid Mile Stone Index`` are equal:

.. image:: https://x-vps.com/static/images/synced_milestones.png
   :alt: synced_milestone

Another option is to run the following command on the server's command line (make sure the port matches your IRI API port)::

  curl -s http://localhost:14265 -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}'| jq '.latestSolidSubtangleMilestoneIndex, .latestMilestoneIndex'

This will output 2 numbers which should be equal.

.. note::

    Above command will fail if you don't have ``jq`` installed. See below how to install it.

You can install ``jq``:

**Ubuntu**: ``apt-get install jq -y``

**Centos**: ``yum install jq -y``

Alternatively, use python::

  curl -s http://localhost:14265 -X POST  -H 'X-IOTA-API-Version: 1' -H 'Content-Type: application/json' -d '{"command": "getNodeInfo"}'|python -m json.tool|egrep "latestSolidSubtangleMilestoneIndex|latestMilestoneIndex"


If you have problems getting in sync after a very long time, consider downloading a fully synced database as described here: :ref:`getFullySyncedDB`

If the issue still persists, perhaps difficulties syncing are related to this: :ref:`whyAmISeeingUDPBadLength`


.. _howDoITellIfIamSyncing:

How do I tell if I am syncing with my neighbors
===============================================
You can use IOTA Peer Manager. Have a look at the neighbors boxes. They normally turn red after a while if there's no sync between you and their node.
Here's an example of a healthy neighbor, you can see it is also sending new transactions (green line) and the value of New Transactions increases in time:

.. image:: https://x-vps.com/static/images/healthy_neighbor.png
   :alt: health_neighbor

|

.. _whereToGetLSMI:

Where to get the latest milestone index from
============================================
It used to be possible via the botbox on Slack. And since Slack is no longer in use, you can get it by running:


.. code:: bash

  curl -s https://x-vps.com/lmsi | jq .

This is a value which is based on querying approximately 100 full nodes.

At time of writing, we are still waiting for the official ``botbox`` to be added to IOTA's Discord chat application.


.. _whyIsLSMAlwaysBehind:

Why is latestSolidSubtangleMilestoneIndex always behind latestMilestoneIndex
============================================================================
This is probably the most frequently asked question.

At time of writing, and to the best of my knowledge, there is not one definitive answer. There are probably various factors that might keep the Solid milestone from ever reaching the latest one and thus remaining not fully synced.

I have noticed that this problem exacerbates when the database is relatively large (5GB+). This is mostly never a problem right after a snapshot, when things run much smoother. This might also be related to ongoing "bad" spam attacks directed against the network.

Some things to try:

* Check your IRI logs. Some case in the past have shown a component failing (e.g. ZMQ) which caused milestone to get stuck. The logs might help identify errors. You can use ``iric`` to view logs (Manage Service->IRI->View log). If you don't have ``iric`` you can install it :ref:`iric`.
* If there's nothing seen in IRI logs (no errors), check other services.
* `How to get my node swap less`_
* `Where can I get a fully synced database to help kick start my node`_
* Finding "healthier" neighbors. This one is actually often hard to ascertain -- who is "healthy", probably other fully synced nodes.


.. _nodeSwapLess:

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


.. _revalidateExplain:

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


.. _getFullySyncedDB:

Where can I get a fully synced database to help kick start my node
==================================================================

For the sake of the community, I regularly create a copy of a fully synced database. 

You can use the ``iric`` tool to download and install the database :ref:`iric`, or update manually using the following instructions:


* The full command will only work if you've installed your full node using this tutorial/playbook.

.. code:: bash

  systemctl stop iri && rm -rf /var/lib/iri/target/mainnetdb* && mkdir /var/lib/iri/target/mainnetdb && cd /var/lib/iri/target/mainnetdb && wget -O - https://x-vps.com/iota.db.tgz | tar zxv && chown iri.iri /var/lib/iri -R && systemctl start iri

.. raw:: html

  <iframe width="700" height="100" src="https://x-vps.com" frameborder="0" allowfullscreen></iframe>


.. note::

  There was some debate on the slack channel whether after having imported a foreign database if it is required to run IRI with the ``--revalidate`` or ``--rescan`` flags. Some said they got fully synced without any of these.

To shed some light on what these options actually do, you can read about it in `What are the revalidate and rescan options for`_

.. _lightWalletConnectionRefused:

I try to connect the light wallet to my node but get connection refused
=======================================================================
There are commonly two reasons for this to happen:

If your full node is on a different machine from where the light wallet is running from, there might be a firewall between, or, your full node is not configured to accept external connections.

See :ref:`remote_access`

