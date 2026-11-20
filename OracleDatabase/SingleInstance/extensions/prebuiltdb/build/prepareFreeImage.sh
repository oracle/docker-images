#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: September, 2026
# Author: mohammed.qureshi@oracle.com
# Description: Clean and archive the Free prebuilt database for the final image.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

: "${ORACLE_BASE:?}"
: "${ORACLE_HOME:?}"

# The database must be shut down before cleanup and archiving.
rm -rf "${ORACLE_BASE}/diag" "${ORACLE_BASE}/cfgtoollogs"
if [ -d "${ORACLE_HOME}/assistants/dbca/templates" ]; then
    find "${ORACLE_HOME}/assistants/dbca/templates" -mindepth 1 -delete
fi

# Store only the archive in the final image.
tar --sparse --create \
    --gzip \
    --file="${ORACLE_BASE}/prebuilt-oradata.tar.gz" \
    -C "${ORACLE_BASE}" oradata
rm -rf "${ORACLE_BASE}/oradata"
mkdir -p "${ORACLE_BASE}/oradata"

# Preserve OS files that are outside ORACLE_BASE for the final stage.
mkdir -p /tmp/prebuilt-runtime
if [ -f /etc/oratab ]; then
    cp /etc/oratab /tmp/prebuilt-runtime/oratab
fi
if [ -f /etc/init.d/oracle-free-26ai ]; then
    cp /etc/init.d/oracle-free-26ai /tmp/prebuilt-runtime/oracle-free-26ai
fi
if [ -f /usr/share/doc/oracle-free-26ai/LICENSE ]; then
    cp /usr/share/doc/oracle-free-26ai/LICENSE /tmp/prebuilt-runtime/oracle-free-26ai.LICENSE
fi
