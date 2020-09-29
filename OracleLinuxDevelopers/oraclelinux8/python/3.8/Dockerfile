# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

LABEL "org.opencontainers.image.authors"="Oracle Linux Product Team <ol-ovm-info_ww@oracle.com>" \
      "org.opencontainers.image.url"="https://github.com/oracle/docker-images" \
      "org.opencontainers.image.source"="https://github.com/oracle/docker-images/tree/master/OracleLinuxDevelopers/oraclelinux8/python/3.8" \
      "org.opencontainers.image.vendor"="Oracle America, Inc" \
      "org.opencontainers.image.description"="Oracle Linux 8 (slim) with Python 3.8 installed."

COPY python38.module /etc/dnf/modules.d/python38.module

RUN microdnf install python38 \
                     python38-libs \
                     python38-pip \
                     python38-setuptools && \
    microdnf clean all

CMD ["/bin/python3", "-V"]
