# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf -y install python3.12 python3.12-libs python3.12-pip python3.12-setuptools python3.12-wheel && \
    rm -rf /var/cache/dnf

CMD ["/usr/bin/python3.12", "-V"]
