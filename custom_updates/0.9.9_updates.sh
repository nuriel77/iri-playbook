#!/usr/bin/env bash
# Custom updates for iric version 0.9.9
# Fixes https://grafana.com/blog/2019/08/29/grafana-5.4.5-and-6.3.4-released-with-important-security-fix/
# https://bugzilla.redhat.com/show_bug.cgi?id=1746945

# Pull new patched version
/usr/bin/docker pull grafana/grafana:6.3.4

# Set version in the config file
sed -i 's/^TAG=.*$/TAG=6.3.4/' "$SYSCONFIG_FILE/grafana-server"

# Restart grafana only if it is already active
systemctl status grafana-server >/dev/null 2>&1 && /bin/systemctl restart grafana-server
