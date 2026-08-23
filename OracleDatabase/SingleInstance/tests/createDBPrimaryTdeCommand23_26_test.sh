#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26.0 primary createDatabase TDE DBCA command.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CREATE_DB_FILE="${REPO_ROOT}/dockerfiles/23.26.0/createDB.sh"

if ! grep -Fq 'DBCA_TDE_CONFIG_OPTIONS="-configureTDE true -tdeWalletRoot ${TDE_WALLET_ROOT} -tdeWalletLoginType AUTO -encryptTablespaces ALL"' "${CREATE_DB_FILE}"; then
  echo "FAIL: expected AUTO wallet mode in ${CREATE_DB_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'DBCA_RSP_TEMPLATE="${SCRIPT_BASE_DIR:-$ORACLE_BASE}/$CONFIG_RSP"' "${CREATE_DB_FILE}"; then
  echo "FAIL: expected response template fallback to SCRIPT_BASE_DIR in ${CREATE_DB_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'dbca -silent -createDatabase -createListener LISTENER:1521 -enableArchive "$ENABLE_ARCHIVELOG" -archiveLogDest "$ARCHIVELOG_DIR" -enableForceLogging "$ENABLE_FORCE_LOGGING" ${DBCA_CRED_OPTIONS} ${DBCA_RECOVERY_CONFIG_OPTIONS} -datafileDestination $ORACLE_BASE/oradata -useOMF true -responseFile "$ORACLE_BASE"/dbca.rsp ${DBCA_TDE_CONFIG_OPTIONS} <<< "${TDE_WALLET_PWD}"' "${CREATE_DB_FILE}"; then
  echo "FAIL: expected primary TDE createDatabase command to match the old image path in ${CREATE_DB_FILE}" >&2
  exit 1
fi

echo "PASS: createDBPrimaryTdeCommand23_26_test"
