.. _maintenance:

Maintenance
***********

* `Upgrade IRI`_
* `Upgrade IOTA Monitoring`_
* `Check Database Size`_
* `Check Logs`_
* `Replace Database`_


.. _upgradeIri:

Upgrade IRI
===========


Latest IRI release is available `here <https://github.com/iotaledger/iri/releases/latest>`_.

If a new version has been announced, you can follow this guide to get the new version or use the menu-driven tool ``iric`` to get the latest IRI version.

If using ``iric``, make sure to update it to the latest version before using it to upgrade IRI.

In the following example we assume that the new version is **1.5.0**.


.. note::

  The foundation might announce additional information in tandem with upgrades, for example whether to use the ``--rescan`` flag, remove older database etc.
  If required, additional options can be specified under the ``OPTIONS=""`` value in the configuration file (``/etc/default/iri`` for Ubuntu or ``/etc/sysconfig/iri`` for CentOS). The database folder is in ``/var/lib/iri/target/mainnetdb`` and can be removed using ``systemctl stop iri && rm -rf /var/lib/iri/target/mainnet*``.


You can update IRI using the ``iric`` tool: :ref:`iric`. Make sure that there are no additional manual steps to be taken if any are announced by the Foundation.

To update manually:

Make sure you are running all the commands as 'root' (run ``sudo su`` first). Then, download new IRI to the directory:


.. code:: bash

   export IRIVER=1.5.0 ; curl -L "https://github.com/iotaledger/iri/releases/download/v${IRIVER}/iri-${IRIVER}.jar" --output "/var/lib/iri/target/iri-${IRIVER}.jar"


(Note than for version 1.5.6 the file name has changed to iri-1.5.6-RELEASE.jar!)

Then update the IRI configuration file in place using ``sed``:

In **Ubuntu**::

  sed -i 's/^IRI_VERSION=.*$/IRI_VERSION=1.5.0/' /etc/default/iri

In **CentOS**::

  sed -i 's/^IRI_VERSION=.*$/IRI_VERSION=1.5.0/' /etc/sysconfig/iri

This will update the version line to match, e.g.::

  IRI_VERSION=1.5.0

This requires a iri **restart**: ``systemctl restart iri``.


To verify the new version is loaded:

.. code:: bash

  ps aux|grep iri-1.5.0|grep -vq grep && echo found

Of course, replace the version with the one you expect to see.

This should output ``found`` if okay.


.. _upgradeIotaMonitoring:

Upgrade IOTA Monitoring
=======================

IOTA Prometheus Monitoring is used by Grafana which are the awesome graphs about the full node.

You can update the monitoring using the ``iric`` tool: :ref:`iric`, or update manually using the following instructions:

A new feature has been added to read extra metrics from IRI using ZeroMQ. ZMQ has to be enabled in IRI first **if you haven't done it already**::

  grep -q ^ZMQ_ENABLED /var/lib/iri/iri.ini || echo "ZMQ_ENABLED = true" >>/var/lib/iri/iri.ini && systemctl restart iri

After about 10-30 seconds (depending on how long it takes IRI to restart) you should be able to see the ZMQ port listening for connections::

  lsof -Pni:5556

Output should look similar to::

  java     5192       iota   47u  IPv6 38464889      0t0  TCP *:5556 (LISTEN)

Next we can update iota-prom-exporter and the respective Grafana dashboard::

  cd /opt/iri-playbook && git pull && ansible-playbook -i inventory -v site.yml --tags=iri_ssl,prometheus_config,monitoring_deps,iota_prom_exporter,grafana_config -e overwrite=yes

Now you should be able to open Grafana and see the new row of metrics (ZMQ).

If you encounter errors when running the command, depending on the error, please refer to :ref:`httpErrorUnauthorized` or :ref:`gitConflicts`.

.. _checkDatabaseSize:

Check Database Size
===================
You can check the size of the database using ``du -hs /var/lib/iri/target/mainnetdb/``, e.g.::

  # du -hs /var/lib/iri/target/mainnetdb/
  4.9G    /var/lib/iri/target/mainnetdb/

.. note::

   To check free space on the system's paritions use ``df -h``
   If one of the paritions' usage exceeds 85% you should consider a cleanup.
   Don't worry about the /boot paritition though.


.. _checkLogs:

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


.. _replaceDatabase:

Replace Database
================
At any time you can remove the existing database and start sync all over again.
This is required if you know your database is corrupt (don't assume, use the community's help to verify such suspicion) or if you want your node to sync more quickly.

To remove an existing database:

1. stop IRI: ``systemctl stop iri``.

2. delete the database: ``rm -rf /var/lib/iri/target/mainnet*``

3. start IRI: ``systemctl start iri``

If you want to import an already existing database, check :ref:`getFullySyncedDB`.
