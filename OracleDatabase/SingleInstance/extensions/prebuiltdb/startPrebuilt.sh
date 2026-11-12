#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: September, 2026
# Author: mohammed.qureshi@oracle.com
# Description: Extract the Free prebuilt database and invoke the Oracle entrypoint.
#              Retry interrupted extraction before starting the database.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -e

ORACLE_BASE="${ORACLE_BASE:-/opt/oracle}"
RUN_FILE="${RUN_FILE:-runOracle.sh}"
ORADATA_DIR="${ORACLE_BASE}/oradata"
ORADATA_ARCHIVE="${ORACLE_BASE}/prebuilt-oradata.tar.gz"
EXTRACTION_MARKER="${ORADATA_DIR}/.prebuilt-extracting"

# True Cache creates its own instance from the primary database.
if [ "${TRUE_CACHE:-false}" != "true" ] && [ -f "${ORADATA_ARCHIVE}" ]; then
    mkdir -p "${ORADATA_DIR}"

    ORADATA_CONTENTS=$(find "${ORADATA_DIR}" -mindepth 1 -maxdepth 1 -print -quit)
    if [ -e "${EXTRACTION_MARKER}" ] || [ -z "${ORADATA_CONTENTS}" ]; then
        touch "${EXTRACTION_MARKER}"
        echo "Expanding prebuilt database files."
        tar --extract \
            --gzip \
            --file="${ORADATA_ARCHIVE}" \
            --directory="${ORACLE_BASE}"
        rm -f "${EXTRACTION_MARKER}"
    fi
fi

exec "${ORACLE_BASE}/${RUN_FILE}" "$@"
