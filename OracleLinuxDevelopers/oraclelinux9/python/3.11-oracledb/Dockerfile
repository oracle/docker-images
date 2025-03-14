# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux9-python:3.11

RUN dnf -y install oraclelinux-developer-release-el9 && \
    dnf -y install python3.11-oracledb && \
    # Optionally install Oracle Instant Client to use python-oracledb Thick mode
    # dnf -y install oracle-instantclient-release-23ai-el9 && \
    # dnf -y install oracle-instantclient-basic && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "--version"]
