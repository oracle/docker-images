# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

COPY python36.module /etc/dnf/modules.d/python36.module

RUN microdnf install oracle-instantclient-release-el8 oraclelinux-developer-release-el8 && \
    microdnf install libaio \
                     oracle-instantclient-basic \
                     python36 \
                     python3-pip \
                     python3-setuptools \
                     python36-cx_Oracle \
                     && \
    microdnf clean all

CMD ["/bin/python3", "-V"]
