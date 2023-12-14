# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y install python3.11 python3.11-pip python3.11-setuptools python3.11-wheel && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "-V"]
