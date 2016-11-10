#!/bin/sh

# confd does not yet allow for dynamically setting keys in the
# TOML file. To get around this we will make the substitution here
# ahead of invoking the process.

# Works around https://github.com/kelseyhightower/confd/issues/310
sed -i.orig s#APP_NAME#$APP_NAME# \
  /etc/confd/conf.d/99-app.toml \
  /etc/confd/templates/99-app.template \
  /etc/confd/conf.d/00-upstream-blue.toml.toml \
  /etc/confd/templates/00-upstream-blue.toml.template \
  /etc/confd/conf.d/00-upstream-blue.template.toml \
  /etc/confd/templates/00-upstream-blue.template.template \
  /etc/confd/conf.d/00-upstream-green.toml.toml \
  /etc/confd/templates/00-upstream-green.toml.template \
  /etc/confd/conf.d/00-upstream-green.template.toml \
  /etc/confd/templates/00-upstream-green.template.template

# Okay now we can run nginx
exec nginx -g "daemon off;"
