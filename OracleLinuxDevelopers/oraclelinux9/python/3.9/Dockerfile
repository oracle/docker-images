# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf -y install python3 python3-libs python3-pip python3-setuptools && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "-V"]
