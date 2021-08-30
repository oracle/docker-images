# Copyright (c) 2020, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

# Enable the right module stream for microdnf
COPY python38.module /etc/dnf/modules.d/python38.module

RUN dnf -y module enable python38 && \
    dnf -y install python36 python3-pip python3-setuptools && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "-V"]
