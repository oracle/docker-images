#!/bin/sh

# The hostname will be the container short hash which will be different for
# each container, thus enough to show, for example, a round robin balancing
# strategy
echo "<h1>Container Hash: $HOSTNAME</h1>" > /usr/share/nginx/html/index.html

# Use `exec` so that PID 1 is the nginx process and not this script
exec /usr/sbin/nginx -g "daemon off;"
