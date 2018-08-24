.. raw:: html

  <meta name="description" content="A fully automated full node installer based on Ansible. Including Peer manager, graphs, alerting, utility scripts and an extensive wiki.">
  <meta name="author" content="Nuriel Shem-Tov">
  <meta name="keywords" lang="en" content="tangle IOTA full node instructions iri installation server centos ubuntu tangle guide wiki">
  <title>IOTA Full Node Installation wiki</title> 
  
.. image:: https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Iota_logo.png/320px-Iota_logo.png
      :alt: IOTA

|

The IOTA Full Node Installer (IRI)
##################################

.. image:: https://readthedocs.org/projects/iri-playbook/badge/?version=master
   :target: http://iri-playbook.readthedocs.io/en/master/?badge=master
   :alt: Documentation Status

Welcome to IRI-playbook full node installer!

To install your node, check the "click-'n-go" installation (recommended) here :ref:`getting_started_quickly`.

This Installer Includes
=======================

* Fully automated installation
* Configuration of firewall and security
* All services running in Docker containers
* Automatically configure the java memory limits based on your system's RAM
* Introduction on how to connect a wallet to your full node
* Install IOTA Peer Manager to manage neighbors
* Serve IOTA Peer Manager and Graphs password protected via HTTPS (secure)
* Optionally install `Nelson <https://gitlab.com/semkodev/nelson.cli>`_ for automatic peering.
* Optionally install `Field <https://gitlab.com/semkodev/field.cli>`_ to "plug" your node under a public load balancer.
* Install monitoring graphs, big thanks to Chris Holliday's `IOTA Exporter <https://github.com/crholliday/iota-prom-exporter>`_.

Please star the playbook's repository on github: `iri-playbook <https://github.com/nuriel77/iri-playbook>`_

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
   docker
   securityhardening
   iric
   troubleshooting
   faq
   uninstall
   glossary
   appendix
   disclaimer
   donations
