#!/bin/sh
# confd does not yet allow for dynamically setting keys in the
# TOML file. To get around this we will make the substitution here
# ahead of invoking the process.

# Works around https://github.com/kelseyhightower/confd/issues/310
sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/conf.d/nginx.toml.template \
    > /etc/confd/conf.d/nginx.toml

sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/templates/nginx.conf.template_orig \
    > /etc/confd/templates/nginx.conf.template

# Okay now we can run nginx
exec nginx -g "daemon off;"
