# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

LABEL "org.opencontainers.image.authors"="Oracle Linux Product Team <ol-ovm-info_ww@oracle.com>" \
      "org.opencontainers.image.url"="https://github.com/oracle/docker-images" \
      "org.opencontainers.image.source"="https://github.com/oracle/docker-images/tree/master/OracleLinuxDevelopers/oraclelinux7/nodejs/10-oracledb" \
      "org.opencontainers.image.vendor"="Oracle America, Inc" \
      "org.opencontainers.image.description"="Oracle Linux 7 (slim) with Node.js 10 installed \
      and Oracle Database connectivity enabled."

RUN yum -y install oracle-nodejs-release-el7 oracle-release-el7 && \
    yum-config-manager --disable ol7_developer_nodejs12 && \
    yum-config-manager --enable ol7_developer_nodejs10 && \
    yum -y install nodejs node-oracledb-node10 && \
    rm -rf /var/cache/yum/*

ENV NODE_PATH=/usr/lib/node_modules

CMD ["/bin/node", "-v"]
