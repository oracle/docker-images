# Copyright (c) 2020, 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y install oraclelinux-developer-release-el8 && \
    dnf -y module enable python36 && \
    dnf -y install python36 python3-pip python3-setuptools python3-oracledb && \
    # Optionally install Oracle Instant Client to use python-oracledb Thick mode
    # dnf -y install oracle-instantclient-release-el8 && \
    # dnf -y install oracle-instantclient-basic && \
    rm -rf /var/cache/dnf


CMD ["/bin/python3", "--version"]
