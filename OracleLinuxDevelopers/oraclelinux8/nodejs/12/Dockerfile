# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"

COPY nodejs.module /etc/dnf/modules.d/nodejs.module

RUN microdnf install nodejs \
                     nodejs-nodemon npm && \
    microdnf clean all

CMD ["/bin/node", "-v"]
