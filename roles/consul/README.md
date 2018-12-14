# Consul HAProxy Template Loader

This role will enable consul and consul-template to control HAProxy.

Some information from https://github.com/nuriel77/iri-lb-haproxy

## Table of contents

  * [Enabling the Feature](#enabling-the-feature)
  * [HAProxy](#haproxy)
    * [Commands](#commands)
  * [Consul](#consul)
    * [Commands](#commands)
  * [Tags](#tags)
  * [Health Check Options](#health-check-options)
  * [Service JSON Files](#service-json-files)
  * [Status](#status)
  * [Appendix](#appendix)
    * [File Locations](#file-locations)

## Enabling the Feature

Make sure you are user `root`, then enter the playbook's directory:

```sh
cd /opt/iri-playbook
```

Enable the feature by configuring the variables file:

```sh
grep -qir "^consul_enabled: [yes|true]" group_vars/all/z-consul-override.yml >/dev/null 2>&1 || echo "consul_enabled: yes" >> group_vars/all/z-consul-override.yml
```

When configuring multiple nodes, add set the option `api_port_remote` to true:

```sh
grep -qir "^api_port_remote: [yes|true]" group_vars/all/z-consul-override.yml >/dev/null 2>&1 || echo "api_port_remote: yes" >> group_vars/all/z-consul-override.yml
```

Run the playbook, make sure you are referencing the correct `inventory` file (you might have created a new customized one, e.g. `inventory-multi`?)

```sh
ansible-playbook -i inventory-multi -v site.yml --tags=consul_role
```

## HAProxy

HAProxy is configured by default with 2 backends:

1. Default backend

2. PoW backend (has a lower maxconn per backend to avoid PoW DoS)

Consul-template uses a haproxy.cfg.tmpl file -- this file is configured on the fly and provided to haproxy.

### Commands

#### Stats
Example view stats from admin TCP socket:

```sh
echo "show stat" | socat stdio tcp4-connect:127.0.0.1:9999
```
Alternatively, use a helper script:

```sh
show-stat
```
or
```sh
show-stat services
```

This will result in an output like this:
```sh
# pxname,svname,status,weight,addr
iri_pow_back,159.69.xxx.xxx:14265,UP,1,159.69.xxx.xxx:14265
iri_pow_back,159.69.xxx.xxx:14265,UP,1,159.69.xxx.xxx:14265
iri_pow_back,159.69.xxx.xxx:14265,UP,1,159.69.xxx.xxx:14265
iri_back,159.69.xxx.xxx:14265,UP,1,159.69.xxx.xxx:14265
iri_back,159.69.xxx.xxx:14265,UP,1,159.69.xxx.xxx:14265
iri_back,159.69.xxx.xxx:14265,UP,1,159.69.xxx.xxx:14265
```

If only the first line appears then there are no available backends. This can be for any of the following reasons:

* Nothing is registered in Consul
* Health-checks are failing
* HAProxy health check is failing

Check HAProxy logs (`journalctl -u haproxy -e -f`) and/or Consul health check's output whether the state is passing.

#### LB Registery Helper Script
The script has been installed and made available, e.g.:

List all registered backends in Consul:
```sh
lbreg -l
```

List health checks status on current Consul host:
```sh
lbreg -c
```

Register a new backend service on current Consul host:
```sh
lbreg -a -b http://1.2.3.4:14265 --check-args="-i,-n,3,-p,-u" --tags="haproxy.maxconn=7,haproxy.scheme=http,haproxy.pow=true"
```

Remove a backend service from current host:
```sh
lbreg -r -b http://1.2.3.4:14265
```

For more options run `lbreg -h`.

For information about tags and health check arguments read further on.

#### IP Stick Table
HAProxy supports IP stick table on which it tracks client IP addresses for rate limiting policies and more.

When setup with multiple nodes, all HAProxy peers share the stick table.

You can watch the table's status, example:

```sh
echo 'show table iri_back' | socat stdio tcp4-connect:127.0.0.1:9999
```

Or to watch it live:
```sh
watch -n.5 "echo 'show table iri_back' | socat stdio tcp4-connect:127.0.0.1:9999"
```

## Consul

Consul exposes a simple API to register services and healthchecks. Each registered service includes a healthcheck (a simple script) that concludes whether a service is healthy or not. Based on the service's health the backend becomes active or disabled in HAProxy.

Consul Template listens to consul and processes any changes on key value store, services or their healthchecks. E.g. if a new service is added, consul template will reload HAProxy with the new service (IRI node). If a service's healthcheck is failing, consul template will reload HAproxy, removing the failed service.

### Commands

Check consul cluster members (e.g. when running consul in a cluster/multiple nodes). Output should show all members of the cluster with status Alive:
```sh
docker exec -it consul consul members
```

Export the Consul master token to a variable so it can be reused when using curl:
```sh
export CONSUL_HTTP_TOKEN=$(cat /etc/consul/consul_master_token)
```

Example view all registered services on catalog (Consul cluster) level:
```sh
curl -s -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X GET http://localhost:8500/v1/catalog/services | jq .
```

Example view detailed iri service from catalog (cluster-wide):
```sh
curl -s -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X GET http://localhost:8500/v1/catalog/service/iri | jq .
```

Example register a service (IRI node):
```sh
curl -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X PUT -d@service.json http://localhost:8500/v1/agent/service/register
```

Example deregister a service (IRI node):
```sh
curl -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X PUT http://localhost:8500/v1/agent/service/deregister/10.100.0.10:14265
```

View all health checks on this agent:
```sh
curl -s -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X GET http://localhost:8500/v1/agent/checks | jq .
```

View all services on this agent:
```sh
curl -s -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X GET http://localhost:8500/v1/agent/services | jq .
```

See Consul's API documentation for more information: https://www.consul.io/api/index.html

## Tags

Consul can store a list of tags per service (backend).

Consul-template makes use of these tags in order to configure a backend.

Here is a list of the available tags and what they mean:


NAME                     | DESCRIPTION                                            | OPTIONS      | DEFAULT
-------------------------|--------------------------------------------------------------------------------
haproxy.maxconn          | Maximum allowed concurrent connections to this backend | integer      | 1
haproxy.maxconnpow       | Maximum allowed concurrent connections to this backend's PoW | integer | 1
haproxy.scheme           | The scheme used by this node                           | http, https  | http
haproxy.pow              | Whether this backend supports PoW                      | false, true, only | false
haproxy.sslverify        | Verify SSL of this backend (not yet implemented)       | 0, false | false
haproxy.weight           | Load balancer backend weight                           | integer | 1

## Healthcheck Options

The health check script is located in `/usr/local/bin/node_check.sh` and mounted into the Consul container so that it can be executed as a health check.

Each registered service can have a `Check` spec registered with it. Consul will run these periodic health checks to ensure the backend is healthy.

Command line options for the script can be viewed when running `/usr/local/bin/node_check.sh -h`:

```sh
-a [address]       API endpoint
-t [seconds]       Seconds until connection timeout
-n [integer]       Minimum neighbors to expect
-m [version]       Minimum version to expect
-w [seconds]       Maximum allowed duration for API response
-p                 Check if node allows PoW (attachToTangle)
-k                 Skip TLS verification
-i                 Ignore/skip REMOTE_LIMIT_API commands check
-u                 Ignore unsynced node (e.g. PoW only node)
-h                 Print help and exit
```

The script's location within Consul's container is `/scripts/node_check.sh`. Hence why the `Check` specs in the JSON definitions below are using this location.

## Service JSON files

In the directory `roles/shared-files` you will find some JSON files. These are service and health checks definitions used to register a new service (IRI node) to consul.

Here is an example with some explanation:
```
{
  "ID": "10.10.0.110:15265",    <--- This is the ID of the service. Using this ip:port combination we can later delete the service from Consul.
  "Name": "iri",                <--- This is the name of the Consul service. This should be set to 'iri' for all added nodes.
  "tags": [
    "haproxy.maxconn=7",        <--- This tag will ensure that this IRI node is only allowed maximum 7 concurrent connections
    "haproxy.scheme=http",      <--- The authentication scheme to this IRI node is via http
    "haproxy.pow=false"         <--- This node will not allow PoW (attachToTangle disabled)
  ],
  "Address": "10.10.0.110",     <--- The IP address of the node
  "Port": 15265,                <--- The port of IRI on this node
  "EnableTagOverride": false,
  "Check": {
    "id": "10.10.0.110:15265",  <--- Just a check ID
    "name": "API 10.10.0.110:15265", <--- Just a name for the checks
    "args": [
      "/bin/bash",
      "/scripts/node_check.sh",
      "-a",
      "http://10.10.0.110:15265",
      "-i"                      <--- This script and options will be run to check the service's health
    ],
    "Interval": "30s",          <--- The check will be run every 30 seconds
    "timeout": "5s",            <--- Timeout will occur if the check is not finished within 5 seconds
    "DeregisterCriticalServiceAfter": "1m" <--- If the health is critical, the service will be de-registered from Consul
  }
}
```

Here is an example of a service (IRI node) that supports PoW:
```
{
  "ID": "10.10.0.110:15265",     <--- Service unique ID
  "Name": "iri",                 <--- We always use the same service name 'iri' to make sure this gets configured in Haproxy
  "tags": [
    "haproxy.maxconn=7",         <--- Max concurrent connections to this node
    "haproxy.scheme=http",       <--- connection scheme (http is anyway the default)
    "haproxy.pow=true"           <--- PoW enabled node
  ],
  "Address": "10.10.0.110",
  "Port": 15265,
  "EnableTagOverride": false,
  "Check": {
    "id": "10.10.0.110:15265-pow",
    "name": "API 10.10.0.110:15265",
    "args": [
      "/bin/bash",
      "/scripts/node_check.sh",
      "-a",
      "http://10.10.0.110:15265",
      "-i",
      "-p"                       <--- Note the `-p` in the arguments, that means we validate PoW works.
    ],
    "Interval": "30s",
    "timeout": "5s",
    "DeregisterCriticalServiceAfter": "1m"
  }
}
```

A simple service's definition:
```
{
  "ID": "10.80.0.10:16265",
  "Name": "iri",
  "tags": [],
  "Address": "10.80.0.10",
  "Port": 16265,
  "EnableTagOverride": false,
  "Check": {
    "id": "10.80.0.10:16265",
    "name": "API http://node01.iota.io:16265",
    "args": [
      "/bin/bash",
      "/scripts/node_check.sh",
      "-a",
      "http://node01.iota.io:16265",
      "-i",
      "-m",
      "1.4.1.7"                  <--- Note that we ensure the API version is minimum 1.4.1.7
    ],
    "Interval": "30s",
    "timeout": "5s",
    "DeregisterCriticalServiceAfter": "1m"
  }
}

```

HTTPS enabled service/node:
```
{
  "ID": "10.10.10.115:14265",
  "Name": "iri",
  "tags": [
    "haproxy.weight=10",    <--- sets weight for HAPRoxy
    "haproxy.scheme=https", <--- scheme is https
    "haproxy.sslverify=0"   <--- Do not SSl verify the certificate of this node
  ],
  "Address": "10.10.10.115",
  "Port": 14265,
  "EnableTagOverride": false,
  "Check": {
    "id": "10.10.10.115:14265",
    "name": "10.10.10.115:14265",
    "args": [
      "/bin/bash",
      "/scripts/node_check.sh",
      "-a",
      "https://10.10.10.115:14265",
      "-i",
      "-k"                  <--- `-k` skips verifying SSL when running healthchecks.
    ],
    "Interval": "30s",
    "timeout": "5s",
    "DeregisterCriticalServiceAfter": "1m"
  }
}
```

## Appendix

### File Locations

Consul's configuration file:
```sh
/etc/consul/conf.d/main.json
```

Bash script that runs the IRI node health checks:
```sh
/usr/local/bin/node_check.sh
```

HAProxy's configuration file:
```sh
/etc/haproxy/haproxy.cfg
```

Consul's systemd control file:
```sh
/etc/systemd/system/consul.service
```

Consul-template systemd file:
```sh
/etc/systemd/system/consul-template.service
```

Consul-template haproxy template
```sh
/etc/haproxy/haproxy.cfg.tmpl
```

Consul template binary:
```sh
/opt/consul-template/consul-template
```

Consul template plugin script
```sh
/opt/consul-template/consul-template-plugin.py
```
