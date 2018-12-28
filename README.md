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
- Optional: [Nelson](https://gitlab.com/semkodev/nelson.cli)
- Monitoring for IRI + Graphs amazing work of [Chris Holliday](https://github.com/crholliday/iota-prom-exporter)

For a "click-'n-go" installation see: [Getting Started Quickly](https://iri-playbook.readthedocs.io/en/feat-docker/getting-started-quickly.html#getting-started-quickly)

For the full tutorial use the [Wiki](http://iri-playbook.readthedocs.io/en/master/index.html)*

## Screenshots Monitoring
![graph_a](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/top_new.png)

![graph_b](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/zmq.png)

![graph_c](https://raw.githubusercontent.com/crholliday/iota-prom-exporter/master/images/neighbors.png)


## Requirements
A redhat/centos or debian/ubuntu node where you want to have the node running on.

Latest Ansible installation for your distribution (http://docs.ansible.com/ansible/latest/intro_installation.html)

Playbook was tested with:
  - Ansible>=2.4
  - Ubuntu 16.04
  - Ubuntu 18.04
  - Debian 9.5
  - CentOS 7.4 and 7.5



Please feel free to contribute.


### Configure host
This playbook can be installed locally or on a remote host (given you have SSH access to it)

If you want to install to a remote host, edit the `inventory` and set the name and IP accordingly (i.e. hostname FQDN)


## Run playbook

Simply run:
```sh
ansible-playbook -i inventory -v site.yml
```


### Installing Specific Roles

You can install a specific role (or skip) by using:
```sh
--tags=first-role-name,second-role-name or --skip-tags=rolename,etc
```

For example, to skip the monitoring role:
```sh
ansible-playbook -i inventory -v site.yml --skip-tags=monitoring_role
```

To find available roles run `grep "\- .*_role$" roles/*/tasks/main.yml`:
```sh
# grep "\- .*_role$" roles/*/tasks/main.yml
roles/iotapm/tasks/main.yml:    - iotapm_role
roles/iri/tasks/main.yml:    - iri_role
roles/monitoring/tasks/main.yml:    - monitoring_role
```

Note that some roles are dependant on other roles having been installed. For example, the monitoring_role depends on iri_role.

Specifying tags or skipping tags is mostly handy when upgrading a role.


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

### Uninstall

Uninstall feature works on best effort. All related files and services will be removed, and firewall configuration reverted:
```sh
ansible-playbook -i inventory site.yml --tags=uninstall -e uninstall_playbook=yes
```

### Overwrite/Update Configuration Files

#### Configuration Files
By default the playbook will not overwrite essential configuration files which have already been deployed, as this might discard values configured by the user.

In order to overwrite or update configuration files, the extra environment variable "overwrite=true" can be set i.e. `-e overwrite=true` when running the playbook.

This will backup existing configuration files with a timestamp.

#### Variable Files
The playbook has a directory `group_vars/all/` with a collection of variable files. These are used by the playbook. Variables can be overriden using the `-e somevar=someval` argument when running the playbook.

Another way to override the variables declared in `group_vars/all/` files is to create a new "override" file. Since the variable files are processed alphabetically, you can create a file called `group_vars/all/zzz-override.yml` and any variable declared in it will override any previously declared variable.
