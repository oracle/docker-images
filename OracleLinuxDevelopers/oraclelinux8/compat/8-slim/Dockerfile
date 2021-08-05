# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oraclelinux:8

# This adds microdnf to the normal image so that any automation that relies on
# it being installed continues to work
RUN dnf install -y microdnf && \
    rm -rf /var/cache/dnf
