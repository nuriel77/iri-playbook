.. raw:: html

  <meta name="description" content="A fully automated full node installer based on Ansible. Including Peer manager, graphs, alerting, utility scripts and an extensive wiki.">
  <meta name="author" content="Nuriel Shem-Tov">
  <meta name="keywords" lang="en" content="tangle IOTA full node instructions iri installation server centos ubuntu tangle guide wiki">
  <title>IOTA Full Node Installation wiki</title> 
  
.. image:: https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Iota_logo.png/320px-Iota_logo.png
      :alt: IOTA

|

IOTA Full Node Installation wiki
################################

.. image:: https://readthedocs.org/projects/iri-playbook/badge/?version=master
   :target: http://iri-playbook.readthedocs.io/en/master/?badge=master
   :alt: Documentation Status

For a "click-'n-go" installation (recommended) see :ref:`getting_started_quickly`.

Watch `this video <https://youtu.be/oT0uuYK7lH8>`_ on how simple it is to install a node using the IRI playbook! (credits to discord user TangleAid)

In this installation
====================

* Automate the installation
* Take care of firewalls
* Automatically configure the java memory limit based on your system's RAM
* Explain how to connect a wallet to your full node
* Install IOTA Peer Manager
* Serve IOTA PM and Graphs password protected via HTTPS
* Optionally install `Nelson <https://github.com/SemkoDev/nelson.cli>`_.
* Install monitoring graphs. Big thanks to Chris Holliday's `IOTA Exporter <https://github.com/crholliday/iota-prom-exporter>`_.
* Email alert notifications manager

Feel free to star this repository: `iri-playbook <https://github.com/nuriel77/iri-playbook>`_

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
   securityhardening
   iric
   troubleshooting
   faq
   uninstall
   glossary
   appendix
   disclaimer
   donations
