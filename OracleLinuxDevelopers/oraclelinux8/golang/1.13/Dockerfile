# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

COPY go-toolset.module /etc/dnf/modules.d/go-toolset.module

RUN microdnf install go-toolset && \
    microdnf clean all

CMD ["/bin/go", "version"]
