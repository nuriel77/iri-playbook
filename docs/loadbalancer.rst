.. _LoadBalancer:

#############
Load Balancer
#############

The new release of IRI-playbook Docker version introduces a valuable feature: a highly available load balancer based on `HAProxy <http://www.haproxy.org>`_ and `Consul <https://www.consul.io/>`_ as the registry backend.

HAProxy is installed by default on all IRI Playbook installations. When running on a single node it doesn’t really function as a load balancer, but simply as a reverse proxy for IRI’s API port. Nonetheless, it includes rate-limiting and other security policies out-of-the-box.

Consul is used in combination with Consul-template to provide HAProxy with a dynamic registry of backend nodes. This means that you can register multiple IRI nodes to Consul to benefit from HAProxy’s load balancing capability.

.. note::

  It is strongly recommended **NOT** to use the load balancer feature to register unknown nodes. Please make sure you only use the load balancer feature for your own cluster of nodes. There is no way to check whether unknown nodes are up to no good.

Disclaimer: I take no responsibility for any problems that might arise due to ignoring the recommendation above.

Overview
========


Consul
------
Basically, every IRI node you deploy has HAProxy installed on it and is able to enable Consul in a cluster mode. Consul nodes share a database of key/value and distributed services and health-checks registry. A service, in our case is an IRI node. The health-check associated with a service can be a simple bash script to run some validations on the service.

Each IRI node registers itself in its locally running Consul daemon, subsequently, it becomes visible to all other Consul daemons. When a new node is registered, Consul initiates health checks to that node. If the node is considered healthy, it will become available across the entire cluster on all the instances of HAProxy. Health checks run periodically, and if a failure is detected, that nodes become unavailable on all HAProxy nodes until it recovers. 

Consul can run in two modes: server and agent. Server mode in itself is also an agent, but extends to being a cluster member that can form a quorum with other server-mode nodes. You can deploy 3 or more consul servers to form a highly available, fault-tolerant cluster (3 or more nodes are required to achieve quorum: always use an odd number equal to or larger than 3). 

In the most basic setup, the IRI Docker Playbook will install all IRI nodes with Consul in server mode. This will form a very robust cluster.

An important note about Consul is: when you register a service, the node on which you have registered the service becomes its “parent”. If this node becomes unavailable, so does any service that has been registered on it.

HAProxy
-------
When Consul role is enabled during an IRI playbook run, it replaces HAPRoxy’s default configuration file with a template. This template is populated by the Consul-template service. The Consul-template service watches Consul for any changes in service and/or health check registry.
When a new service is registered and health check passes, Consul-template automatically edits HAPRoxy’s configuration template and issues a hot-reload. Same happens if a service is deregistered, updated or health check fails.


Configuration Steps
===================

Options
-------
There are two options:

1. Single IRI node/load balancer
2. Three or more IRI nodes/load balancers

For the first option, a single IRI node is required, installed with the IRI Playbook Docker version. This node is simply a normal but it also runs Consul and Consul-template. It registers its own IRI to its HAPRoxy and is available to receive API calls. It is possible to manually register new services (IRI nodes) to it.

The disadvantage of a single node is being a single-point-of-failure (SPoF). If it is down, all the instances that are registered on it become unreachable through it.

For the second options, the recommendation is to use at least three nodes in order to form a minimum requirement for creating quorum. In addition, an odd number of nodes should be used. With an odd number of nodes it is possible to reach consensus on who are the active nodes.

Deployment of the mutli-node setup requires following the manual installation instructions of the IRI Docker playbook.

At time of writing, there is no centralized management interface for administration of all nodes in the cluster via a centralized panel.

High Availability
-----------------
High availability is possible to achieve when installing a minimum of 3 cluster nodes: it is very unlikely that more than one node at the same time would fail. If one node fails, there are 2 nodes still operational.

In this documentation we won’t get into configuration of a virtual IP and keepalived, which is one option for keeping a working/accessible IP on one of the nodes (keepalived uses VRRP protocol and makes sure the virtual IP is always configured on at least one active node).

We’ll be using simple DNS multiple A records. For example, take the hostname ``my.iotacluster.io``. In any DNS panel it is possible to configure multiple A records for this hostname. An A record points a hostname (or hostnames) to an IP address.

Say we have 3 nodes:

.. code:: bash

  101.202.30.10
  101.202.30.20
  101.202.30.30

We configure ``my.iotacluster.io`` with 3 A records, each record with each node’s IP address pointing to the hostname ``my.iotacluster.io``. A TTL (time-to-live) can usually be configured: it defines the time a DNS server should cache the record. For our scenario it is recommended to set it low (e.g. 60 seconds).

DNS uses round-robin by default (the associated IP address to the hostname are rotated in each reply from the DNS server).


[More to follow, work in progress...]
