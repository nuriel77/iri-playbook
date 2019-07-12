#!/usr/bin/env bash
# Custom updates for iric version 0.9.3

# Cleanup old port variable
sed -i '/^IRI_TCP_PORT/d' "$SYSCONFIG_FILE"
