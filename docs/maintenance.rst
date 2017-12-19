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

There are two ways to upgrade IRI to a new version. The first method described here is the recommended one.


First Method
------------

1. Edit the iri.yml file: ``/opt/iri-playbook/group_vars/all/iri.yml``

2. Set the version you with to upgrade to in ``iri_version`` (latest is 1.4.1.4).

3. For version 1.4.1.4, edit the ``iri_jar_checksum`` and set ``sha256:0154b57bf37b031142ae2a0d884b8bb65efdd5e08f670898f0ae82f1b41fba9b``

4. Save the file and run ``cd /opt/iri-playbook/ && ansible-playbook -i inventory -v site.yml --tags=iri_role``


To verify the version has been updated, run:

.. code:: bash

   ps aux|grep -q iri-1.4.1.4 && echo found

Of course, replace the version with the one you expect to see.

This should output ``found`` if okay.


Second Method
-------------

If a new version of IRI has been released, it should suffice to replace the jar file.
The jar file is located e.g.::

  /var/lib/iri/target/iri-1.4.1.2.jar


Let's say you downloaded a new version iri-1.6.2.jar (latest release is available `here <https://github.com/iotaledger/iri/releases/latest>`_.
You can download it to the directory::

  cd /var/lib/iri/target/ && curl -L https://github.com/iotaledger/iri/releases/download/v1.6.2/original-iri-1.6.2.jar --output iri-1.6.2.jar

Then edit the IRI configuration file:

In **Ubuntu**::

   /etc/default/iri

In **CentOS**::

  /etc/sysconfig/iri

And update the version line to match, e.g.::

  IRI_VERSION=1.6.2

This requires a iri restart (``systemctl restart iri``).

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
