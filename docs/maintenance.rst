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


Latest IRI release is available `here <https://github.com/iotaledger/iri/releases/latest>`_.

If a new version has been announced, you can follow this guide to get the new version.

In the following example we assume that the new version is **1.4.1.6**.

Download new IRI to the directory:

.. code:: bash

   export IRIVER=1.4.1.6 ; curl -L "https://github.com/iotaledger/iri/releases/download/v${IRIVER}/iri-${IRIVER}.jar" --output "/var/lib/iri/target/iri-${IRIVER}.jar"

Then update the IRI configuration file in place using ``sed``:

In **Ubuntu**::

  sed -i 's/^IRI_VERSION=.*$/IRI_VERSION=1.4.1.6/' /etc/default/iri

In **CentOS**::

  sed -i 's/^IRI_VERSION=.*$/IRI_VERSION=1.4.1.6/' /etc/sysconfig/iri

This will update the version line to match, e.g.::

  IRI_VERSION=1.4.1.6

This requires a iri **restart**: ``systemctl restart iri``.


To verify the new version is loaded:

.. code:: bash

  ps aux|grep iri-1.4.1.6|grep -vq grep && echo found

Of course, replace the version with the one you expect to see.

This should output ``found`` if okay.


.. warning::

   In version 1.4.1.6 a new API command has been added: ``setApiRateLimit``. It is advised to add it to the limited commands list.
   This will prevent external connections from being able to use this command.
   
   On **Ubuntu** edit the file ``/etc/default/iri``, find the line beginning with REMOTE_LIMIT_API and append it on the end:

   ``REMOTE_LIMIT_API="removeNeighbors, addNeighbors, interruptAttachingToTangle, attachToTangle, getNeighbors, setApiRateLimit"``

   On **CentOS** you can find the configuration file in ``/etc/sysconfig/iri`` and do the same as above.

   See :ref:`usingNano` on how to edit files.


.. note::

  The foundation might announce additional information regarding upgrades, for example whether to use the ``--rescan`` flag etc.
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
