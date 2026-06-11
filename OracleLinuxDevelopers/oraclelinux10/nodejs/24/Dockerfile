# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:10

RUN dnf -y install nodejs24 nodejs-nodemon npm && \
    dnf clean all && \
    rm -rf /var/cache/dnf

CMD ["/bin/node", "-v"]
