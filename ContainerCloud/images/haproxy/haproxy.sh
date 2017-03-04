#!/bin/sh
# confd does not yet allow for dynamically setting keys in the
# TOML file. To get around this we will make the substitution here
# ahead of invoking the process.

# Works around https://github.com/kelseyhightower/confd/issues/310
sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/conf.d/haproxy.toml.template \
    > /etc/confd/conf.d/haproxy.toml

sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/templates/haproxy.cfg.template_orig \
    > /etc/confd/templates/haproxy.cfg.template

# Okay now we can run haproxy
exec /usr/sbin/haproxy \
    -f /etc/haproxy/haproxy.cfg
    -db
