# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux10-python:3.12

RUN dnf -y install oraclelinux-developer-release-el10 && \
    dnf -y install python3.12-oracledb && \
    rm -rf /var/cache/dnf

CMD ["/bin/python3", "--version"]
