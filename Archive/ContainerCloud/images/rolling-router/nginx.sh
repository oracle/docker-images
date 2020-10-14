#!/bin/sh

# confd does not yet allow for dynamically setting keys in the
# TOML file. To get around this we will make the substitution here
# ahead of invoking the process.

# Works around https://github.com/kelseyhightower/confd/issues/310
sed -i.orig s#APP_NAME#$APP_NAME# \
  /etc/confd/conf.d/00-upstream.toml.toml \
  /etc/confd/templates/00-upstream.toml.template \
  /etc/confd/conf.d/00-upstream.template.toml \
  /etc/confd/templates/00-upstream.template.template

# Okay now we can run nginx
exec nginx -g "daemon off;"
