# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

LABEL "org.opencontainers.image.authors"="Oracle Linux Product Team <ol-ovm-info_ww@oracle.com>" \
      "org.opencontainers.image.url"="https://github.com/oracle/docker-images" \
      "org.opencontainers.image.source"="https://github.com/oracle/docker-images/tree/master/OracleLinuxDevelopers/oraclelinux8/php/7.4-apache" \
      "org.opencontainers.image.vendor"="Oracle America, Inc" \
      "org.opencontainers.image.description"="Oracle Linux 8 (slim) with PHP 7.4 and Apache 2.4.37 installed."

COPY *.module /etc/dnf/modules.d/

RUN microdnf install httpd \
                     httpd-filesystem \
                     httpd-tools \
                     mod_http2 \
                     mod_ssl \
                     openssl \
                     php \
                     php-cli \
                     php-common \
                     php-json \
                     php-mbstring \
                     php-mysqlnd \
                     php-pdo \
                     php-xml && \
    microdnf clean all && \
    # Disable event module and enable prefork so that mod_php is enabled
    sed -i 's/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/' /etc/httpd/conf.modules.d/00-mpm.conf && \
    sed -i 's/LoadModule mpm_event_module modules\/mod_mpm_event.so/#LoadModule mpm_event_module modules\/mod_mpm_event.so/' /etc/httpd/conf.modules.d/00-mpm.conf && \
    # Disable HTTP2 as it is not supported with the prefork module
    sed -i 's/LoadModule http2_module modules\/mod_http2.so/#LoadModule http2_module modules\/mod_http2.so/' /etc/httpd/conf.modules.d/10-h2.conf && \
    sed -i 's/LoadModule proxy_http2_module modules\/mod_proxy_http2.so/#LoadModule proxy_http2_module modules\/mod_proxy_http2.so/' /etc/httpd/conf.modules.d/10-proxy_h2.conf && \
    # Create self-signed certificate for mod_ssl
    openssl req -x509 -nodes -newkey rsa:4096 \
                -keyout /etc/pki/tls/private/localhost.key \
                -out /etc/pki/tls/certs/localhost.crt \
                -days 3650 -subj '/CN=localhost' && \
    # Redirect logging to stdout/stderr for container logging to work
    sed -i 's/;error_log = syslog/error_log = \/dev\/stderr/' /etc/php.ini && \
    ln -sf /dev/stdout /var/log/httpd/access_log && \
    ln -sf /dev/stderr /var/log/httpd/error_log && \
    # Disable userdirs and the auto-generated welcome message
    rm -f /etc/httpd/conf.d/{userdir.conf,welcome.conf}

CMD ["/sbin/httpd", "-DFOREGROUND"]
