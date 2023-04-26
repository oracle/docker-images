# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf -y module enable nodejs:18 && \
    dnf -y install nodejs nodejs-nodemon npm && \
    rm -rf /var/cache/dnf

CMD ["/bin/node", "-v"]
