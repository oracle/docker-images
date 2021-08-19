# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

# Enable the right module stream for microdnf
COPY php.module /etc/dnf/modules.d/php.module

RUN dnf -y module enable php:7.2 && \
    dnf -y install php-cli \
                   php-common \
                   php-json \
                   php-mbstring \
                   php-mysqlnd \
                   php-pdo \
                   php-xml && \
    rm -rf /var/cache/dnf

CMD ["/bin/php", "-v"]
