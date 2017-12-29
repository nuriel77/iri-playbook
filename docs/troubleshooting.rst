
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
