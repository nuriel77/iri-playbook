# IOTA IRI Fullnode Ansible Playbook

This playbook will install and configure and IOTA full node.

In addition, it will install and configure iota-pm, a GUI to view/manage the full node.




## Requirements
A redhat/centos or debian/ubuntu node where you want to have the node running on.

Latest Ansible installation for your distribution (http://docs.ansible.com/ansible/latest/intro_installation.html)

Playbook was tested with Ansible>=2.4




### Configure host
This playbook can be installed locally or on a remote host (given you have SSH access to it)

If you want to install to a remote host, edit the `inventory` and set the name and IP accordingly (i.e. hostname FQDN)




### Configure options
In `groups_vars/all/*.yml` you will find files with some configuration options and comments.

Edit the files as required (most importantly check the latest IRI version and edit accordingly).




## Run playbook

Simply run:
```sh
ansible-playbook -i inventory -v site.yml
```



To re-install iri (this will remove any existing database) or for example to install a different version after having edited the version in the `groups_vars/all/*.yml` file:

First, if you already have iri running:
```sh
sudo systemctl stop iri
```

Then:
```sh
ansible-playbook -i inventory -v site.yml -e "remove_iri_basedir=1"
```

