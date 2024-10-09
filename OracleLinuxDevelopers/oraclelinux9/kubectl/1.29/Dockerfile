# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# OCNE 1.9 - Kubectl 1.29

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf install -y oracle-olcne-release-el9 && \
    dnf config-manager --enable ol9_olcne19 ol9_addons ol9_baseos_latest ol9_appstream && \
    dnf install -y kubectl && \
    rm -rf /var/cache/dnf

ENTRYPOINT ["kubectl"]

CMD ["--help"]