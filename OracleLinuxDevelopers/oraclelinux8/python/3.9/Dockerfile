# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

COPY python39.module /etc/dnf/modules.d/python39.module

RUN microdnf install python39 \
                     python39-libs \
                     python39-pip \
                     python39-setuptools && \
    microdnf clean all

CMD ["/bin/python3", "-V"]
