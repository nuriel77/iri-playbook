.. image:: https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Iota_logo.png/320px-Iota_logo.png
      :alt: IOTA

|

IOTA Full Node Installation wiki
################################

.. image:: https://readthedocs.org/projects/iri-playbook/badge/?version=latest
     :target: http://iri-playbook.readthedocs.io/en/latest/?badge=latest
  :alt: Documentation Status

For a "click-'n-go" installation see `Getting Started Quickly`_.

In this installation
====================

* Automate the installation
* Take care of firewalls
* Automatically configure the java memory limit based on your system's RAM
* Explain how to connect a wallet to your full node
* Install IOTA Peer Manager
* Make IOTA Peer Manager accessible via the browser
* Password protect IOTA Peer Manager
* Install monitoring graphs. Big thanks to Chris Holliday's `IOTA Exporter <https://github.com/crholliday/iota-prom-exporter>`_.

Work in progress
================

* Integrate alerting/notifications when node is not healthy
* Instead of compiling IRI, download the jar to expedite the installation a bit
* Security hardening steps
* Make it possible to install graphs for those who already did this installation. At the moment nodejs version will conflict.

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
   disclaimer
   donations
