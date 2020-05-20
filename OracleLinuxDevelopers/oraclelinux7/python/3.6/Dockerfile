# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum-config-manager --disable ol7_UEKR5 && \
    yum -y install python3 python3-libs python3-pip python3-setuptools && \
    rm -rf /var/cache/yum/*

CMD ["/bin/python3","--version"]