# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM oraclelinux:7-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

RUN yum -y install oracle-php-release-el7 && \
    yum-config-manager --disable ol7_UEKR5 && \
    yum -y install php-fpm \
                   php-json \
                   php-mbstring \
                   php-mysqlnd \
                   php-pdo \
                   php-soap \
                   php-xml && \
    rm -rf /var/cache/yum/* && \
    sed -i '/^listen = /clisten = 0.0.0.0:9000' /etc/php-fpm.d/www.conf && \
    sed -i '/^listen.allowed_clients/c;listen.allowed_clients =' /etc/php-fpm.d/www.conf && \
    sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php-fpm.d/www.conf

EXPOSE 9000

WORKDIR /var/www

CMD ["/sbin/php-fpm", "-F", "-O"]