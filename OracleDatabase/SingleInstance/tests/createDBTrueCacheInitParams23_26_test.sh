#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26.0 True Cache createDB initParams DBCA command.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CREATE_DB_FILE="${REPO_ROOT}/dockerfiles/23.26.0/createDB.sh"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"

if grep -Fq 'INIT_PARAMS="-initParams processes=${INIT_PROCESSES}"' "${CREATE_DB_FILE}"; then
  echo "FAIL: expected True Cache INIT_PROCESSES handling to move out of base createDB.sh ${CREATE_DB_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'export TRUECACHE_DBCA_INIT_PARAMS="processes=${INIT_PROCESSES}"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to translate INIT_PROCESSES into shim initParams in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'set -- "$@" -initParams "${TRUECACHE_DBCA_INIT_PARAMS}"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache DBCA shim to append initParams in ${WRAPPER_FILE}" >&2
  exit 1
fi

echo "PASS: createDBTrueCacheInitParams23_26_test"
