# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

COPY php.module /etc/dnf/modules.d/php.module

RUN microdnf install php-cli \
                     php-common \
                     php-fpm \
                     php-json \
                     php-mbstring \
                     php-mysqlnd \
                     php-pdo \
                     php-soap \
                     php-xml && \
    microdnf clean all && \
    mkdir -p /run/php-fpm && \
    # Enable external access to PHP-FPM
    sed -i '/^listen = /clisten = 0.0.0.0:9000' /etc/php-fpm.d/www.conf && \
    sed -i '/^listen.allowed_clients/c;listen.allowed_clients =' /etc/php-fpm.d/www.conf && \
    # Redirect worker output to stdout for container logging
    sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php-fpm.d/www.conf

EXPOSE 9000

WORKDIR /var/www

CMD ["/sbin/php-fpm", "-F", "-O"]
