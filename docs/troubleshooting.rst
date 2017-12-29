.. _troubleshooting:

###############
Troubleshooting
###############

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

You can identify those files::

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

To view the differeneces run ``diff /tmp/my-changes/my-old-file my-newfile``. The command's output might not be the prettiest; you can choose to handle the conflicts manually.

Once you are done applying your changes, you can proceed to run the playbook command you were about to apply.



.. _httpErrorUnauthorized:

HTTP Error 401 Unauthorized When Running Playbook
=================================================

This is how the error would look like::

  TASK [monitoring : create prometheus datasource in grafana] ************************************************************************************************
  fatal: [localhost]: FAILED! => {"changed": false, "connection": "close", "content": "{\"message\":\"Basic auth failed\"}", "content_length": "31", "content_type": "application/json; charset=UTF-8", "date": "Fri, 29 Dec 2017 10:40:13 GMT", "json": {"message": "Basic auth failed"}, "msg": "Status code was not [200, 409]: HTTP Error 401: Unauthorized", "redirected": false, "status": 401, "url": "http://localhost:3000/api/datasources"}
       to retry, use: --limit @/opt/iri-playbook/site.retry

  PLAY RECAP *************************************************************************************************************************************************


This can happen for a number of reasons. It is most probably a password mismatch between what the playbook sees in ``group_vars/all/iotapm.yml`` under the value ``iotapm_nginx_password`` and perhaps the ``iotapm_nginx_user`` too.

Try to correct this by checking the password which is currently configured in grafana:

.. code:: bash

    grep ^admin /etc/grafana/grafana.ini

The result should look like::

  admin_user = iotapm
  admin_password = hello123

You can try to override the password when running the playbook, appending it to the end of the ansible command, e.g.:

.. code:: bash

   ansible-playbook -i inventory -v site.yml --tags=monitoring_role -e iotapm_nginx_password=hello123

If this doesn't work, there's a way to force-reset the password:

1. Stop grafana-server::

  systemctl stop grafana-server

2. Delete grafana's database::

  rm -f /var/lib/grafana/grafana.db

3. Edit ``/etc/grafana/grafana.ini`` and ensure the correct username and password for the values ``admin_user`` and ``admin_password``.

4. Start grafana-server::

  systemctl start grafana-server


Now you should be able to login to grafana.
