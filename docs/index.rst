.. image:: https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Iota_logo.png/320px-Iota_logo.png
      :alt: IOTA

|

IOTA Full Node Installation wiki
################################

.. image:: https://readthedocs.org/projects/iri-playbook/badge/?version=master
   :target: http://iri-playbook.readthedocs.io/en/master/?badge=master
   :alt: Documentation Status

For a "click-'n-go" installation see :ref:`getting_started_quickly`.

In this installation
====================

* Automate the installation
* Take care of firewalls
* Automatically configure the java memory limit based on your system's RAM
* Explain how to connect a wallet to your full node
* Install IOTA Peer Manager
* Make IOTA Peer Manager accessible via the browser
* Password protect IOTA Peer Manager
* Optionally install `Nelson <https://github.com/SemkoDev/nelson.cli>`_.
* Install monitoring graphs. Big thanks to Chris Holliday's `IOTA Exporter <https://github.com/crholliday/iota-prom-exporter>`_.


.. note::

   If you want to test out the new IRI+Nelson auto-installer in Docker containers (does not include the monitoring graphs and peer manager):
   I am looking for testers: https://github.com/SemkoDev/nelson.cli/tree/master/contrib/ansible-playbook


Work in progress
================

* Integrate alerting/notifications when node is not healthy
* Security hardening steps

|

.. toctree::
   :maxdepth: 2

   introduction
   overview
   getting-started-quickly
   requirements
   installation
   post-installation
   remote-access
   files
   maintenance
   faq
   glossary
   appendix
   disclaimer
   donations
