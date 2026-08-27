#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26 True Cache primary metadata parser.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"

if ! grep -Fq "^[[:space:]]*[^|]+[[:space:]]*\\|[[:space:]]*[^|]+[[:space:]]*\\|[[:space:]]*(true|false)" "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to only accept metadata rows whose final field is true or false in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'Ignoring malformed primary metadata db_name=${resolved_db_name}' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to reject malformed primary db_name metadata in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'PRIMARY_DB_NAME ${PRIMARY_DB_NAME} does not match primary metadata db_name=${resolved_db_name}. Using db_name ${resolved_db_name} for DBCA sourceDB.' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to override a mismatched caller-provided PRIMARY_DB_NAME with live primary metadata in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'Keeping caller-provided PRIMARY_DB_NAME=${PRIMARY_DB_NAME} because primary metadata lookup was unavailable.' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to keep the caller-provided PRIMARY_DB_NAME only when metadata lookup is unavailable in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq "^[[:space:]]*[^|]+[[:space:]]*\\|[[:space:]]*[^|]+[[:space:]]*\\|[[:space:]]*[0-9]+[[:space:]]*$" "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to only accept RAC listener rows with instance, host, and numeric port in ${WRAPPER_FILE}" >&2
  exit 1
fi

echo "PASS: createDBTrueCachePrimaryMetadataParser23_26_test"
