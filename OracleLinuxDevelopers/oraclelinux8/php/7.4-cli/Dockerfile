# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/djelibeybi/oraclelinux8-compat:8-slim

COPY php.module /etc/dnf/modules.d/php.module

RUN microdnf install php-cli \
                     php-common \
                     php-json \
                     php-mbstring \
                     php-mysqlnd \
                     php-pdo \
                     php-xml && \
    microdnf clean all

CMD ["/bin/php", "-v"]
