# Copyright (c) 2020, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oraclelinux-developer-release-el7 && \
    yum -y install python3 \
                   python3-libs \
                   python3-pip \
                   python3-setuptools \
                   python3-oracledb && \
    # Optionally install Oracle Instant Client if you want to use python-oracledb Thick mode
    # yum -y install oracle-instantclient-release-el7 && \
    # yum -y install oracle-instantclient-basic && \
    rm -rf /var/cache/yum/*


CMD ["/bin/python3", "--version"]
