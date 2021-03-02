# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-nodejs-release-el7 && \
    yum-config-manager --disable ol7_developer_nodejs14 && \
    yum-config-manager --enable ol7_developer_nodejs10 && \
    yum -y install nodejs && \
    rm -rf /var/cache/yum/*

CMD ["/bin/node", "-v"]
