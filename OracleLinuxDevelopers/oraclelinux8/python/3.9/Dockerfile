# Copyright (c) 2020, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y module disable python36 && \
    dnf -y module enable python39 && \
    dnf -y install python39 python39-pip python39-setuptools python39-wheel && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "-V"]
