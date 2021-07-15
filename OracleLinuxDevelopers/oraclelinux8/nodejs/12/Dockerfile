# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

COPY nodejs.module /etc/dnf/modules.d/nodejs.module

RUN dnf -y module install nodejs:12 && \
    rm -rf /var/cache/dnf

CMD ["/bin/node", "-v"]
