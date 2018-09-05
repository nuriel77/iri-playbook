# Consul HAProxy Template Loader

Some information from https://github.com/nuriel77/iri-lb-haproxy

## HAProxy

HAProxy is configured by default with 2 backends:

1. Default backend

2. PoW backend (has a lower maxconn per backend to avoid PoW DoS)

Consul-template uses a haproxy.cfg.tmpl file -- this file is configured on the fly and provided to haproxy.

### Commands

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

## Consul

Consul exposes a simple API to register services and healthchecks. Each registered service includes a healthcheck (a simple script) that concludes whether a service is healthy or not. Based on the service's health the backend becomes active or disabled in HAProxy.

Consul Template listens to consul and processes any changes on key value store, services or their healthchecks. E.g. if a new service is added, consul template will reload HAProxy with the new service (IRI node). If a service's healthcheck is failing, consul template will reload HAproxy, removing the failed service.

### Commands

Export the Consul master token to a variable so it can be reused when using curl:
```sh
export CONSUL_HTTP_TOKEN=$(cat /etc/consul/consul_master_token)
```

Example view all registered services on catalog (Consul cluster) level:
```sh
curl -s -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" -X GET http://localhost:8500/v1/catalog/services | jq .
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
