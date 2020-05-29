# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

RUN yum -y install oracle-php-release-el7 oracle-release-el7 && \
    yum-config-manager --disable ol7_UEKR5 && \
    yum -y install httpd \
                   oracle-instantclient19.5-basic \
                   php \
                   php-cli \
                   php-json \
                   php-mbstring \
                   php-mysqlnd \
                   php-pdo \
                   php-xml \
                   php-oci8-19c \
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
