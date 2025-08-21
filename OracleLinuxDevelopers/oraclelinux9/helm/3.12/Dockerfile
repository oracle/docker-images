# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# OCNE 1.8 - Helm 3.12

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf install -y oracle-olcne-release-el9 && \
    dnf config-manager --enable ol9_olcne18 ol9_addons ol9_baseos_latest ol9_appstream && \
    dnf install -y helm && \
    rm -rf /var/cache/dnf

ENTRYPOINT ["helm"]

CMD ["--help"]