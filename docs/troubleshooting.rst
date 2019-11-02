.. _troubleshooting:

###############
Troubleshooting
###############


.. _pastebin:

Upload Logs to Pastebin
=======================

Sometimes it helps to share your logs with someone who can help figure out problems.

First make sure you have the pastebin tool installed.

On **CentOS**: ``yum install -y fpaste``

On **Ubuntu/Debian**: ``apt-get install -y pastebinit``



Below are examples for Ubuntu, Debian and CentOS how to upload various files. You can tweak parameters as required.

Note that the long ``sed`` commands are there to hide IP addresses.

The command will return a URL link which you can share, that will open the logs in the browser.


** DO NOT COPY PASTE BLINDLY, edit commands as required before execution! **

Ubuntu/Debian Logs
------------------

Here are a few examples. You can change the log file name if required.

The two ``sed`` commands can be added in between any command to hide IP addresses: ``sed 's/\([0-9]\{1,3\}\.\)\{3,3\}[0-9]\{1,3\}/x.x.x.x/g'|sed  -r 's#:\[.*\]:([0-9]+)#:\[xxxx:xxxx:xxxx:xxxx\]:\1#g'``.

.. code:: bash

  # Example uploading last 200 lines of main syslog, hide IPv4 and IPv6 addresses
  tail -200 /var/log/syslog | sed 's/\([0-9]\{1,3\}\.\)\{3,3\}[0-9]\{1,3\}/x.x.x.x/g'|sed  -r 's#:\[.*\]:([0-9]+)#:\[xxxx:xxxx:xxxx:xxxx\]:\1#g'| pastebinit -b pastebin.com -P

  # Example uploading iri-playbook log
  cat /var/log/iri-playbook-201801061902.log | pastebinit -b pastebin.com -P


  # Example uploading last 200 lines of iota-pm service log
  journalctl -u iota-pm --no-pager -n 200 | pastebinit -b pastebin.com -P

  # Example uploading last 200 lines of iri service log
  journalctl -u iri --no-pager -n 200 | pastebinit -b pastebin.com -P


CentOS Logs
-----------

Here are a few examples. You can change the log file name if required.

The two ``sed`` commands can be added in between any command to hide IP addresses: ``sed 's/\([0-9]\{1,3\}\.\)\{3,3\}[0-9]\{1,3\}/x.x.x.x/g'|sed  -r 's#:\[.*\]:([0-9]+)#:\[xxxx:xxxx:xxxx:xxxx\]:\1#g'``.


.. code:: bash

  # Example uploading last 200 lines of main syslog, hide IPv4 and IPv6 addresses
  tail -200 /var/log/messages | sed 's/\([0-9]\{1,3\}\.\)\{3,3\}[0-9]\{1,3\}/x.x.x.x/g'|sed  -r 's#:\[.*\]:([0-9]+)#:\[xxxx:xxxx:xxxx:xxxx\]:\1#g'| fpaste -P "yes"

  # Example uploading iri-playbook log
  cat /var/log/iri-playbook-201801061902.log | fpaste -P "yes"


  # Example uploading last 200 lines of iota-pm service log
  journalctl -u iota-pm --no-pager -n 200 | fpaste -P "yes"

  # Example uploading last 200 lines of iri service log
  journalctl -u iri --no-pager -n 200 | fpaste -P "yes"



.. _gitConflicts:

How to Handle Git Conflicts
===========================

This is by no means a git tutorial, and the method suggested here has nothing to do with how one should be using git.


Background
----------

It is simply the case that updates are applied to configuration files over time. A user might have configured values that might later conflict with new updates.

I was looking for a quick solution for users who are not familiar with Linux or git. One idea was to rename all the variable files adding the extension ``.example`` and using those as the "source".

The other solution is the one I am presenting here.

Backup My Changes
-----------------

If you run a ``git pull`` and receive a message about conflicts, e.g.::

  error: Your local changes to the following files would be overwritten by merge:
          somefile
  Please, commit your changes or stash them before you can merge.
  Aborting

This means you've applied changes in files which have already been updated upstream.

The fastest answer is to use ``git stash`` to stash all the changes you've made::

  git stash

This should allow you to run ``git pull`` without any errors. After that you can use ``git stash apply`` to get your changes back.

It is recommended not to edit the variable files in order to avoid such conflicts. You can better create "override" files :ref:`overrideFile`

|

A longer route would be to identify those files which are in conflict::

  git status

And view the changes you've applied::

  git diff

You can run the following command which will backup the files you've changed and allow to pull the updated versions:

.. code:: bash

  mkdir -p /tmp/my-changes && for f in $(git status|grep modified|awk {'print $3'});do cp $f /tmp/my-changes/ ; git checkout -- $f ;done

This will copy any conflicting file into the directory ``/tmp/my-changes``.

At this point you will not have any conflicts and be able to run ``git pull``.


Apply Changes
-------------
The next step is to identify the changes. You can view the files that have been backed up using ``ls -l /tmp/my-changes``.

For each file in that directory find its corresponding (new) updated file: ``find -name filename``.

To view the differences run ``diff /tmp/my-changes/my-old-file my-newfile``. The command's output might not be the prettiest; you can choose to handle the conflicts manually.

Once you are done applying your changes, you can proceed to run the playbook command you were about to apply.



.. _httpErrorUnauthorized:

HTTP Error 401 Unauthorized When Running Playbook
=================================================

This is how the error would look like::

  TASK [monitoring : create prometheus datasource in grafana] ************************************************************************************************
  fatal: [localhost]: FAILED! => {"changed": false, "connection": "close", "content": "{\"message\":\"Basic auth failed\"}", "content_length": "31", "content_type": "application/json; charset=UTF-8", "date": "Fri, 29 Dec 2017 10:40:13 GMT", "json": {"message": "Basic auth failed"}, "msg": "Status code was not [200, 409]: HTTP Error 401: Unauthorized", "redirected": false, "status": 401, "url": "http://localhost:3000/api/datasources"}
       to retry, use: --limit @/opt/iri-playbook/site.retry

  PLAY RECAP *************************************************************************************************************************************************


This can happen for a number of reasons. It is most probably a password mismatch between what the playbook sees in ``group_vars/all/z-installer-override.yml`` under the value ``fullnode_user_password`` and perhaps the ``fullnode_user`` too.


Solution A
----------
Try to correct this by checking the password which is currently configured in grafana:

.. code:: bash

    grep ^admin /etc/grafana/grafana.ini

The result should look like::

  admin_user = iotapm
  admin_password = hello123

You can try to override the password when running the playbook, appending it to the end of the ansible command, e.g.:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --tags=monitoring_role -e fullnode_user_password=hello123


Solution B
----------
If Solution A doesn't work, there's a way to force-reset the password.

This solution also works if you haven't installed Grafana via this tutorial and cannot login.


1. Stop grafana-server:

.. code:: bash

  systemctl stop grafana-server

2. Delete grafana's database:

.. code:: bash

  rm -f /var/lib/grafana/grafana.db

3. Edit ``/etc/grafana/grafana.ini``, set correct values for ``admin_user`` and ``admin_password``.

4. Start grafana-server:

.. code:: bash

  systemctl start grafana-server


Now you should be able to login to grafana.


Error Starting or Restarting IRI
================================

Examples of errors:

Hostname can't be null
----------------------

If you get this message in the logs:

.. code:: bash

  java.lang.IllegalArgumentException: hostname can't be null

It is most likely you have a typo in one (or more) of the neighbors in your configuration file, or the entire line is invalid.

Make sure all neighbors adhere to the format examples:

.. code:: bash

  tcp://some-node.myserver.com:15600
  tcp://[2xxx:7xx:aaaf:111:2222:ff:ffff:xxxx]:12345


.. _fixNginx:

Fix Nginx
=========

If you've tried to enable HTTPS (Let's Encrypt) via an automated script supporting Nginx and your Nginx is no longer working, follow these instructions on how to restore it:


.. code:: bash

  wget -O /etc/nginx/sites-enabled/default https://gist.githubusercontent.com/nuriel77/e847aa6dbb360d277a0313c983e35721/raw/a68e4528fe07a429284cc19b923d72d62a25d2c9/default

And then restart nginx:

.. code:: bash

  systemctl restart nginx

You can verify it is working via:

.. code:: bash

  systemctl status nginx

It should be active.

