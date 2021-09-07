# Copyright (c) 2020, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

RUN dnf -y install oracle-instantclient-release-el8 oraclelinux-developer-release-el8 && \
    dnf -y module enable python36 && \
    dnf -y install oracle-instantclient-basic \
                   python36 python3-pip python3-setuptools python36-cx_Oracle && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "-V"]
