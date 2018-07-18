#!/usr/bin/env bash

# Validate nginx configuration file for Ansible
# To use when running nginx in a Docker container
set -e

DOCKER=/usr/bin/docker
TEMP_CONFIG_FILENAME=
DEST_CONFIG_FILENAME=
REPLACE_ETC_NGINX="n"

while getopts ":t:d:r" opt; do
  case $opt in
    t)
      TEMP_CONFIG_FILENAME="$OPTARG"
      ;;
    d)
      DEST_CONFIG_FILENAME="$OPTARG"
      ;;
    r)
      REPLACE_ETC_NGINX="y"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ "x${TEMP_CONFIG_FILENAME}" = "x" ]; then
    echo "Required argument: -t" >&2
    exit 1
fi

if [ "x${REPLACE_ETC_NGINX}" = "xy" ]; then
    find "$NGINX_CONF_DIR" -type f | xargs sed -i "s#/etc/nginx#$NGINX_CONF_DIR#g"
fi

set +e

$DOCKER run --rm \
  -v /etc/ssl/private:/etc/ssl/private:ro,Z \
  -v $(readlink -f /etc/ssl/certs):/etc/ssl/certs:ro,Z \
  -v /etc/letsencrypt:/etc/letsencrypt:ro,Z \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d:Z \
  -v "${TEMP_CONFIG_FILENAME}":/etc/nginx/conf.d/"${DEST_CONFIG_FILENAME}" \
  nginx:latest \
  nginx -t

RETCODE=$?
exit $RETCODE
