#!/usr/bin/env bash

# Example usage from an Ansible playbook:
# - name: Copy the nginx validate script
#   copy: src=validate-nginx-config.sh dest=/opt/validate-nginx-config.sh mode=0744
#
# - name: Update main nginx config file
#   template:
#     src: nginx.conf.j2
#     dest: /etc/nginx/nginx.conf
#     validate: /opt/validate-nginx-config.sh -t %s -d nginx.conf -r
#
# Or (to actually test it as if a site was enabled):
#
# - name: Update sites-available with new site
#   template:
#     src: nginx/new-site.conf.j2
#     dest: /etc/nginx/sites-available/new-site.conf
#     validate: /opt/validate-nginx-config.sh -t %s -d sites-enabled/new-site.conf -r

set -e

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

NGINX_CONF_DIR=`mktemp -d`
# TODO check if we need to handle symlinks in a special way in cp for validate to work
cp -rTp /etc/nginx/ "$NGINX_CONF_DIR"

if [ "x${DEST_CONFIG_FILENAME}" != "x" ]; then
    mkdir -p `dirname "$NGINX_CONF_DIR"/"$DEST_CONFIG_FILENAME"`
    cp -Tp "$TEMP_CONFIG_FILENAME" "$NGINX_CONF_DIR"/"$DEST_CONFIG_FILENAME"
fi

if [ "x${REPLACE_ETC_NGINX}" = "xy" ]; then
    find "$NGINX_CONF_DIR" -type f | xargs sed -i "s#/etc/nginx#$NGINX_CONF_DIR#g"
fi

set +e

nginx -t -c "$NGINX_CONF_DIR"/nginx.conf
RETCODE=$?

set -e

rm -rf "$NGINX_CONF_DIR"
exit $RETCODE
