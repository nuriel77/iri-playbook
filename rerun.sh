#!/bin/bash
:>/etc/motd
cd /opt/iri-playbook && SKIP_CONFIRM="true" bash fullnode_install.sh rerun
