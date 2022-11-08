# Copyright (c) 2021, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y module enable nodejs:14 && \
    dnf -y install oracle-instantclient-release-el8 oraclelinux-developer-release-el8 && \
    dnf -y install oracle-instantclient-basic node-oracledb-node14 nodejs npm && \
    rm -rf /var/cache/dnf

ENV NODE_PATH=/usr/local/lib/node_modules/

CMD ["/bin/node", "-v"]
