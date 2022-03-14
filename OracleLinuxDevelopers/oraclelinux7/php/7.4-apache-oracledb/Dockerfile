# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-php-release-el7 oracle-release-el7 oracle-instantclient-release-el7 && \
    yum -y install httpd \
                   oracle-instantclient-basic \
                   php \
                   php-cli \
                   php-json \
                   php-mbstring \
                   php-mysqlnd \
                   php-pdo \
                   php-xml \
                   php-oci8-21c \
                   unzip && \
    rm -rf /var/cache/yum/* && \
    # Redirect logging for container usage
    sed -i 's/;error_log = syslog/error_log = \/dev\/stderr/' /etc/php.ini && \
    ln -sf /dev/stdout /var/log/httpd/access_log && \
    ln -sf /dev/stderr /var/log/httpd/error_log && \
    # Remove userdir and welcome module configuration
    rm -f /etc/httpd/conf.d/{userdir.conf,welcome.conf}

EXPOSE 80

CMD ["/sbin/httpd", "-DFOREGROUND"]
