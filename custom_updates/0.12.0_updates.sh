#!/usr/bin/env bash

# This update will install and configure iotacaddy

export NEWT_COLORS='
window=,
'

if ! (whiptail --title "Updates" \
               --yesno "There has been a new service added called IOTA Caddy to perform more efficient PoW. This update will install IOTA Caddy and route all the 'attachToTangle' requests from HAProxy/IRI to IOTA Caddy.\n\nThis update will overwrite any manual changes you might have done to HAProxy configuration.\n\n(Note: if you choose 'no', you will always be able to add this feature later by running 'cd /opt/iri-playbook && /usr/bin/ansible -v site.yml -i inventory --tags=iotacaddy_role,loadbalancer_role -e overwrite=yes -e iotacaddy_enabled=yes'. To persist the update, best configure 'iotacaddy_enabled: yes' in '/opt/iri-playbook/group_vars/all/z-installer-override.yml'\n\nWould you like to apply the new update now?" \
              24 78) then
    grep -q ^iotacaddy_enabled /opt/iri-playbook/group_vars/all/z-installer-override.yml || echo "iotacaddy_enabled: no" >> /opt/iri-playbook/group_vars/all/z-installer-override.yml
    exit
fi

cd /opt/iri-playbook && /usr/bin/ansible-playbook -v site.yml -i inventory --tags=iotacaddy_role,loadbalancer_role -e overwrite=yes
