# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-golang-release-el7 && \
    yum-config-manager --disable ol7_developer_golang114 && \
    yum-config-manager --enable ol7_developer_golang113 && \
    yum -y install golang && \
    rm -rf /var/cache/yum/*

CMD ["/bin/go", "version"]
