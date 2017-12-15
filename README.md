# IOTA IRI Fullnode Ansible Playbook

[![Documentation Status](https://readthedocs.org/projects/iri-playbook/badge/?version=latest)](http://iri-playbook.readthedocs.io/en/latest/?badge=latest)

This playbook will install and configure and IOTA full node.

[![Documentation Status](https://readthedocs.org/projects/iri-playbook/badge/?version=latest)](http://iri-playbook.readthedocs.io/en/latest/?badge=latest)

It will:
- Install and configure IOTA IRI full node
- Install and configure iota-pm: a GUI to view/manage peers
- Password protect iota-pm
- Run iota-pm and IRI as systemd controlled processes (unprivileged users)
- Configure firewalls
- NEW: Monitoring for IRI + Graphs amazing work of Chirs Holliday https://github.com/crholliday/iota-prom-exporter


For a "click-'n-go" installation see: [Getting Started Quickly](http://iri-playbook.readthedocs.io/en/docs/getting-started-quickly.html#getting-started-quickly)

For the full tutorial use the [Wiki](http://iri-playbook.readthedocs.io/en/docs/index.html)

## Screenshots Monitoring
![graph_a](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/top.png)

![graph_b](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/market_all_neighbors.png)

![graph_c](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/neighbors.png)


## Requirements
A redhat/centos or debian/ubuntu node where you want to have the node running on.

Latest Ansible installation for your distribution (http://docs.ansible.com/ansible/latest/intro_installation.html)

Playbook was tested with:
  - Ansible>=2.4
  - Ubuntu 16.04
  - CentOS 7.4



Please feel free to contribute.


### Configure host
This playbook can be installed locally or on a remote host (given you have SSH access to it)

If you want to install to a remote host, edit the `inventory` and set the name and IP accordingly (i.e. hostname FQDN)




### Configure options
In `groups_vars/all/*.yml` you will find files with some configuration options and comments.

Important value to edit is the `iotapm_nginx_password` in the `group_vars/all/iotapm.yml`. Set a strong password.

To edit the password and/or add more users refer to the wiki link up in this README doc.


Edit other options if you want to tweak anything (most importantly check the latest IRI version and edit accordingly).



## Run playbook

Simply run:
```sh
ansible-playbook -i inventory -v site.yml
```


### Skip IRI or IOTA Peer Manager Installations

You can skip IRI's installation:
```sh
ansible-playbook -i inventory -v site.yml --skip-tags=iri_config,iri_firewalld,iri_ufw,iri_config
```

or skip IOTA PM installation:
```sh
ansible-playbook -i inventory -v site.yml --skip-tags=iotapm_deps,iotapm_firewall,iotapm_config
```

### Reinstall or Reconfigure
To re-install iri (this will remove any existing database) or for example to install a different version after having edited the version in the `groups_vars/all/*.yml` file:

First, if you already have iri running:
```sh
sudo systemctl stop iri
```

Then:
```sh
ansible-playbook -i inventory -v site.yml -e "remove_iri_workdir=1"
```
