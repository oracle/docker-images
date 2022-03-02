# Copyright (c) 2020, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y install oraclelinux-developer-release-el8 oracle-instantclient-release-el8 && \
    dnf -y module enable php:7.4 php-oci8:21c && \
    dnf -y install php-cli \
                   php-common \
                   php-json \
                   php-mbstring \
                   php-mysqlnd \
                   php-pdo \
                   php-xml \
                   php-oci8-21c && \
    rm -rf /var/cache/dnf

CMD ["/bin/php", "-v"]
