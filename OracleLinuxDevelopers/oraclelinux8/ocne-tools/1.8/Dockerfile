# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# hadolint ignore=DL3007
FROM ghcr.io/oracle/oci-cli:latest

USER root

RUN dnf install -y oracle-olcne-release-el8 && \
    dnf config-manager --enable ol8_olcne18 ol8_addons ol8_baseos_latest ol8_appstream && \
    dnf install -y helm kubectl && \
    rm -rf /var/cache/dnf

COPY help.sh /opt/help.sh

USER oracle

ENTRYPOINT []

CMD ["/bin/bash", "/opt/help.sh"]