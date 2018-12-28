.. _uninstall:

Uninstall
*********

It is possible to remove the services and configuration files installed by the playbook.

.. warning::

  It is not possible to remove everything installed by the playbook. For example, some packages might have already been installed by the user prior to running the playbook. In addition, enabling of firewalls, main nginx file configuration files and some additional essentials are not reverted/removed.


1. In order to run the uninstaller, please become root via ``sudo su -``.

2. Run:

.. code:: bash

    cd /opt/iri-playbook && ansible-playbook -i inventory site.yml --tags=uninstall -e uninstall_playbook=yes

