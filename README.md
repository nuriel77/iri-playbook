# IOTA IRI Fullnode Ansible Playbook

[![Documentation Status](https://readthedocs.org/projects/iri-playbook/badge/?version=feat-docker)](http://iri-playbook.readthedocs.io/en/master/?badge=feat-docker)

This playbook will install and configure the IOTA full node. In addition:

- Install and configure iota-pm: a GUI to view/manage peers
- Password protected, HTTPS accessible dashboards
- Run all services as systemd controlled processes (unprivileged users)
- Alerting and notifications
- Configure firewalls
- `iric` configuration tool
- HAProxy for Wallet/API connections
- Monitoring for IRI + Graphs amazing work of [Chris Holliday](https://github.com/crholliday/iota-prom-exporter)

For installation see [Getting Started Quickly](https://iri-playbook.readthedocs.io/en/feat-docker/getting-started-quickly.html#getting-started-quickly)

Documentation at [Wiki](http://iri-playbook.readthedocs.io/en/feat-docker/index.html)

## Screenshots Monitoring
![graph_a](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/top_new.png)

![graph_b](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/zmq.png)

![graph_c](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/neighbors.png)


## Requirements

Requirements can be found [here](https://iri-playbook.readthedocs.io/en/feat-docker/requirements.html)

## Installation for Development

Enter the branch you are testing on and run the installer:
```sh
BRANCH="dev-branch"; GIT_OPTIONS="-b $BRANCH" bash <(curl -s "https://raw.githubusercontent.com/nuriel77/iri-playbook/$BRANCH/fullnode_install.sh")
```

Please feel free to contribute.
