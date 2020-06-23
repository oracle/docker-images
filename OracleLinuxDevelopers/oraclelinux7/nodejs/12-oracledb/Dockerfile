# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

RUN yum -y install oracle-nodejs-release-el7 oracle-release-el7 && \
    yum-config-manager --disable ol7_UEKR5 && \
    yum -y install nodejs node-oracledb-node12 && \
    rm -rf /var/cache/yum/*

ENV NODE_PATH=/usr/lib/node_modules

CMD ["/bin/node", "-v"]
