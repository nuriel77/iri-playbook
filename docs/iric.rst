.. _iric:

Fullnode IRI Configuration Utility
**********************************

``iric`` is a new tool I started working on in February 2018. It is currently under development, but ready to use should you find it helpful.


Many new users who have little experience with Linux have recently installed a fullnode using the playbook. Lacking experience with Linux makes it hard to manage the fullnode.

Some users find it exciting and want to learn more about Linux. The playbook's documentation includes some basics such as configuring firewalls, security, checking logs, managing services etc.

For those who don't have the time to take a dive into Linux, I started working on ``iric`` -- a utility to help manage a full node. Its aim is to include tasks related to management of the fullnode.

Instead of having to copy & paste long commands from the documentation, one can choose to use this menu-driven utility.


Feel free to use it. Feedback is most welcome.


If you don't have ``iric`` installed (older playbook installations) you can add it by running:

.. code:: bash

  cd /opt/iri-playbook/ && git pull && ansible-playbook -i inventory site.yml -v --tags=scripts,nbctl_config



To run the utility, type: ``iric``. This will open it up:

.. image:: https://raw.githubusercontent.com/nuriel77/iri-playbook/master/docs/images/iric_01.png
      :alt: iric01


Not much to explain here. Enjoy!
