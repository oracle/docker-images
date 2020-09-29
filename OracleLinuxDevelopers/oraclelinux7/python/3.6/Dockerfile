# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

LABEL "org.opencontainers.image.authors"="Oracle Linux Product Team <ol-ovm-info_ww@oracle.com>" \
      "org.opencontainers.image.url"="https://github.com/oracle/docker-images" \
      "org.opencontainers.image.source"="https://github.com/oracle/docker-images/tree/master/OracleLinuxDevelopers/oraclelinux7/python/3.6" \
      "org.opencontainers.image.vendor"="Oracle America, Inc" \
      "org.opencontainers.image.description"="Oracle Linux 7 (slim) with Python 3.6 installed."

RUN yum -y install python3 \
                   python3-libs \
                   python3-pip \
                   python3-setuptools && \
    rm -rf /var/cache/yum/*

CMD ["/bin/python3","--version"]