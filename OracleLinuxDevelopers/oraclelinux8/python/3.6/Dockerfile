# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

COPY python36.module /etc/dnf/modules.d/python36.module

RUN microdnf install python36 \
                     python3-pip \
                     python3-setuptools && \
    microdnf clean all

CMD ["/bin/python3", "-V"]
