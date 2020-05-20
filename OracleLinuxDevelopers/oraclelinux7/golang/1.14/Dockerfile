# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

RUN yum -y install oracle-golang-release-el7 && \
    yum-config-manager --disable ol7_UEKR5 && \
    yum -y install golang && \
    rm -rf /var/cache/yum/*

CMD ["/bin/go", "version"]
