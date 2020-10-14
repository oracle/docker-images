#!/bin/sh

sed -i -e s/HOSTNAME/${HOSTNAME}/g /usr/share/nginx/html/index.html

# Use `exec` so that PID 1 is the nginx process and not this script
exec /usr/sbin/nginx -g "daemon off;"
