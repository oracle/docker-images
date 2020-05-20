# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

COPY php.module /etc/dnf/modules.d/php.module

RUN microdnf install php-cli \
                     php-common \
                     php-fpm \
                     php-json \
                     php-mbstring \
                     php-xml && \
    microdnf clean all

CMD ["/bin/php", "-v"]
