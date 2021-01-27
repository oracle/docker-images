# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-release-el7 oraclelinux-developer-release-el7 && \
    yum -y install python3 \
                   python3-libs \
                   python3-pip \
                   python3-setuptools \
                   python36-cx_Oracle && \
    rm -rf /var/cache/yum/*

CMD ["/bin/python3","--version"]
