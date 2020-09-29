# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

LABEL "org.opencontainers.image.authors"="Oracle Linux Product Team <ol-ovm-info_ww@oracle.com>" \
      "org.opencontainers.image.url"="https://github.com/oracle/docker-images" \
      "org.opencontainers.image.source"="https://github.com/oracle/docker-images/tree/master/OracleLinuxDevelopers/oraclelinux8/golang/1.13" \
      "org.opencontainers.image.vendor"="Oracle America, Inc" \
      "org.opencontainers.image.description"="Oracle Linux 8 (slim) with Golang 1.13 installed."

COPY go-toolset.module /etc/dnf/modules.d/go-toolset.module

RUN microdnf install go-toolset && \
    microdnf clean all

CMD ["/bin/go", "version"]
