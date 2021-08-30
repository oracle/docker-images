# Copyright (c) 2021, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

# Enable the right module stream for microdnf
COPY go-toolset.module /etc/dnf/modules.d/go-toolset.module

RUN dnf -y module enable go-toolset:ol8 && \
    dnf -y install go-toolset && \
    rm -rf /var/cache/dnf

CMD ["/bin/go", "version"]
