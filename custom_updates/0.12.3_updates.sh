#!/usr/bin/env bash

cd /opt/iri-playbook && git pull && ansible-playbook -i inventory site.yml -v --tags=local_deps
test -e /usr/bin/pip2 && /usr/bin/pip2 install python-gilt
test -e /usr/bin/pip3 && /usr/bin/pip3 install python-gilt
