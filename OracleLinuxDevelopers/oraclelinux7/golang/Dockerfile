# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-golang-release-el7 && \
    yum -y install golang && \
    rm -rf /var/cache/yum/*

CMD ["/bin/go", "version"]
