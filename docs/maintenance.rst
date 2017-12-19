.. _maintenance:

Maintenance
***********

* `Upgrade IRI`_
* `Upgrade IOTA Monitoring`_
* `Check Database Size`_
* `Check Logs`_
* `Replace Database`_


.. upgradeIri::

Upgrade IRI
===========


If a new version of IRI has been released, it should suffice to replace the jar file.
The jar file is located e.g.::

  /var/lib/iri/target/iri-1.4.1.2.jar


Latest release is available `here <https://github.com/iotaledger/iri/releases/latest>`_.

In the following example we assume that the new version is 1.6.2.

You can download it to the directory::

  cd /var/lib/iri/target/ && curl -L https://github.com/iotaledger/iri/releases/download/v1.6.2/iri-1.6.2.jar --output iri-1.6.2.jar

Then edit the IRI configuration file:

In **Ubuntu**::

   /etc/default/iri

In **CentOS**::

  /etc/sysconfig/iri

And update the version line to match, e.g.::

  IRI_VERSION=1.6.2

This requires a iri restart (``systemctl restart iri``).


To verify the new version is loaded:

.. code:: bash

   ps aux|grep -q iri-1.4.1.4 && echo found

Of course, replace the version with the one you expect to see.

This should output ``found`` if okay.


.. note::

  The foundation normally announces additional information regarding upgrades, for example whether to use the ``--rescan`` flag etc.
  Such options can be specified in the ``OPTIONS=""`` value in the same file.


.. upgradeIotaMonitoring::

Upgrade IOTA Monitoring
=======================

IOTA Prometheus Monitoring is used by Grafana which are the awesome graphs about the full node.

Running this command will check for updates, if any, will update iota-prom-exporter::

  cd /opt/iri-playbook/ && ansible-playbook -i inventory site.yml --tags=iota_prom_exporter -v


.. checkDatabaseSize:: 

Check Database Size
===================
You can check the size of the database using ``du -hs /var/lib/iri/target/mainnetdb/``, e.g.::

  # du -hs /var/lib/iri/target/mainnetdb/
  4.9G    /var/lib/iri/target/mainnetdb/

.. note::

   To check free space on the system's paritions use ``df -h``
   If one of the paritions' usage exceeds 85% you should consider a cleanup.
   Don't worry about the /boot paritition though.


.. checkLogs::

Check Logs
==========
Follow the last 50 lines of the log (iri):

.. code:: bash

   journalctl -n 50 -f -u iri

For iota-pm:

.. code:: bash

   journalctl -n 50 -f -u iota-pm

Click 'Ctrl-C' to stop following and return to the prompt.

Alternatively, omit the ``-f`` and use ``--no-pager`` to view the logs.


.. replaceDatabase::

Replace Database
================
At any time you can remove the existing database and start sync all over again.
This is required if you know your database is corrupt (don't assume, use the community's help to verify such suspicion) or if you want your node to sync more quickly.

To remove an existing database:

1. stop IRI: ``systemctl stop iri``.

2. delete the database: ``rm -rf /var/lib/iri/target/mainnet*``

3. start IRI: ``systemctl start iri``

If you want to import an already existing database, check the [FAQ](#where-can-i-get-a-fully-synced-database-to-help-kick-start-my-node) -- there's information on who to do that.
