#!/usr/bin/env bash
# First argument to the script is the file to export
# Second argument to the script is the mainnetdb directory
set -e

if [[ -z "$1" ]]
then
    PROMFILE="/var/run/prometheus/mainnetdb_size.prom"
else
    PROMFILE="$1"
fi

if [[ -z "$2" ]]
then
    DB_DIR=/var/lib/iri/target/mainnetdb
else
    DB_DIR="$2"
fi

PROM_DIR=$(dirname "${PROMFILE}")
DB_SIZE=$(du -s -b "${DB_DIR}"| awk {'print $1'})

[[ ! -d "$PROM_DIR" ]] && mkdir -p "$PROM_DIR"

echo "mainnetdb_dir_size_bytes{directory=\"${DB_DIR}\"} ${DB_SIZE}" >>"$PROMFILE.$$"

if [ -n "$PROMFILE" ];then
    mv "$PROMFILE.$$" "$PROMFILE"
fi
