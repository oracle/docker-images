# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/djelibeybi/oraclelinux8-compat:8-slim

COPY go-toolset.module /etc/dnf/modules.d/go-toolset.module

RUN dnf -y module install go-toolset && \
    rm -rf /var/cache/dnf

CMD ["/bin/go", "version"]
