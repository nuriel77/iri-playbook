#!/usr/bin/env bash
# Custom updates for iric version 0.8.2

# Cleanup old port variable
sed -i '/^IRI_TCP_PORT/d' "$SYSCONFIG_FILE"
