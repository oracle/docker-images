#!/bin/sh
# confd does not yet allow for dynamically setting keys in the
# TOML file. To get around this we will make the substitution here
# ahead of invoking the process.

# Works around https://github.com/kelseyhightower/confd/issues/310
sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/conf.d/prometheus.toml.template \
    > /etc/confd/conf.d/prometheus.toml

sed s#OCCS_BACKEND_KEY#$OCCS_BACKEND_KEY# \
    /etc/confd/templates/prometheus.yml.template_orig \
    > /etc/confd/templates/prometheus.yml.template

# Okay now we can run prometheus
exec /bin/prometheus -config.file=/etc/prometheus/prometheus.yml
