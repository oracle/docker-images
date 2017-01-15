#!/bin/sh
# confd does not yet allow for dynamically setting keys in the
# TOML file. To get around this we will make the substitution here
# ahead of invoking the process.

# Works around https://github.com/kelseyhightower/confd/issues/310
sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/conf.d/hello-world.toml.template \
    > /etc/confd/conf.d/hello-world.toml

sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/templates/hello-world.conf.template_orig \
    > /etc/confd/templates/hello-world.conf.template

# Okay now we can run confd
exec /usr/bin/confd \
    -backend stackengine \
    -node $KV_IP:$KV_PORT \
    -scheme http \
    -auth-token $OCCS_API_TOKEN \
    -interval 5
