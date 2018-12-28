.. _files:

Files and Locations
*******************
Here's a list of files and locations that might be useful to know:

IRI configuration file (changes require iri to restart)::

   Ubuntu: /etc/default/iri
   CentOS: /etc/sysconfig/iri


IOTA Peer Manager configuration file (changes require iota-pm restart)::

   Ubuntu: /etc/default/iota-pm
   CentOS: /etc/sysconfig/iota-pm


IRI installation path::

   /var/lib/iri/target

IRI database::

   /var/lib/iri/target/mainnet*

Grafana configuration file::

   /etc/grafana/grafana.ini

Grafana Database file::

  /var/lib/grafana/grafana.db

Prometheus configuration file::

  /etc/prometheus/prometheus.yaml

IOTA-Prom-Exporter configuration file::

  /opt/prometheus/iota-prom-exporter/config.js

Alert Manager configuration file::

  /opt/prometheus/alertmanager/config.yml

HAProxy configuration file::

  /etc/haproxy/haproxy.cfg

Nelson configuration file::

  /etc/nelson/nelson.ini

