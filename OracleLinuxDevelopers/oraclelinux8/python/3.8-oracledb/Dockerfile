# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:8-slim

COPY python38.module /etc/dnf/modules.d/python38.module

RUN microdnf install oracle-instantclient-release-el8 oraclelinux-developer-release-el8 && \
    microdnf install libaio \
                     oracle-instantclient-basic \
                     python38 \
                     python38-libs \
                     python38-pip \
                     python38-setuptools && \
    microdnf clean all && \
    pip3.8 install cx_Oracle

CMD ["/bin/python3", "-V"]
