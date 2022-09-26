# Copyright (c) 2020, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y module enable nodejs:14 && \
    dnf -y install nodejs npm && \
    rm -rf /var/cache/dnf

CMD ["/bin/node", "-v"]
