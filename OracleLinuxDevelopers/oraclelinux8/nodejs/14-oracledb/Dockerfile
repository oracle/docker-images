# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

# Enable the right module stream for microdnf
COPY nodejs.module /etc/dnf/modules.d/nodejs.module

RUN dnf -y install oracle-instantclient-release-el8 oraclelinux-developer-release-el8 && \
    dnf -y install oracle-instantclient-basic node-oracledb-node14 && \
    rm -rf /var/cache/dnf

ENV NODE_PATH=/usr/local/lib/node_modules/

CMD ["/bin/node", "-v"]
