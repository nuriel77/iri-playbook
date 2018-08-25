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

I strongly recommend to use ``iric`` in order to upgrade IRI's version when a new release is out.

Latest IRI release is available `here <https://github.com/iotaledger/iri/releases/latest>`_.

If a new version has been announced, a new docker image for IRI should be made available and can be pulled via ``iric`` (upgrade IRI).

.. note::

  The foundation might announce additional information in tandem with upgrades, for example whether to use the ``--rescan`` flag, remove older database etc.
  If required, additional options can be specified under the ``OPTIONS=""`` value in the configuration file (``/etc/default/iri`` for Ubuntu and Debian or ``/etc/sysconfig/iri`` for CentOS). The database folder is in ``/var/lib/iri/target/mainnetdb`` and can be removed using ``systemctl stop iri && rm -rf /var/lib/iri/target/mainnet*``.


You can update IRI using the ``iric`` tool: :ref:`iric`. Make sure that there are no additional manual steps to be taken if any are announced by the Foundation.


.. _upgradeIotaMonitoring:

Upgrade IOTA Monitoring
=======================

IOTA Prometheus Monitoring is used by Grafana which are the awesome graphs about the full node.

You can update the monitoring using the ``iric`` tool: :ref:`iric`.

.. _checkDatabaseSize:

Check Database Size
===================
You can check the size of the database using ``du -hs /var/lib/iri/target/mainnetdb/``, e.g.::

  # du -hs /var/lib/iri/target/mainnetdb/
  4.9G    /var/lib/iri/target/mainnetdb/

.. note::

   To check free space on the system's partitions use ``df -h``
   If one of the partitions' usage exceeds 85% you should consider a cleanup.
   Don't worry about the /boot partitition though.


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
If you want to re-download a fully synced database please refer to :ref:`getFullySyncedDB` on how to get this done.
