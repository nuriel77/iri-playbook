#!/bin/bash
:>/etc/motd
cd /opt/iri-playbook && NO_CONFIRM="true" bash fullnode_install.sh rerun
