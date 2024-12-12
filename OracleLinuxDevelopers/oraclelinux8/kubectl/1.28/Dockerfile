# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# OCNE 1.8 - Kubectl 1.28

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf install -y oracle-olcne-release-el8 && \
    dnf config-manager --enable ol8_olcne18 ol8_addons ol8_baseos_latest ol8_appstream && \
    dnf install -y kubectl && \
    rm -rf /var/cache/dnf

ENTRYPOINT ["kubectl"]

CMD ["--help"]