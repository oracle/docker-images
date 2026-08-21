#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26.0 readiness check to keep primary auth unchanged
#              while using SYSDBA only for True Cache local readiness checks.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECK_FILE="${REPO_ROOT}/dockerfiles/23.26.0/checkDBStatus.sh"

helper_count="$(grep -F -c 'sqlplus_local_connect_string() {' "${CHECK_FILE}" || true)"
true_cache_sysdba_count="$(grep -F -c 'echo "/ as sysdba"' "${CHECK_FILE}" || true)"
plain_count="$(grep -F -c 'echo "/"' "${CHECK_FILE}" || true)"
callsite_count="$(grep -F -c 'sqlplus -s "$(sqlplus_local_connect_string)" << EOF' "${CHECK_FILE}" || true)"
legacy_unquoted_sysdba_count="$(grep -F -c 'sqlplus -s / as sysdba << EOF' "${CHECK_FILE}" || true)"

if [ "${helper_count}" -ne 1 ]; then
  echo "FAIL: expected one sqlplus_local_connect_string helper in ${CHECK_FILE}, found ${helper_count}" >&2
  exit 1
fi

if [ "${true_cache_sysdba_count}" -ne 1 ]; then
  echo "FAIL: expected helper to return quoted SYSDBA connect string for True Cache in ${CHECK_FILE}" >&2
  exit 1
fi

if [ "${plain_count}" -ne 1 ]; then
  echo "FAIL: expected helper to preserve plain / auth for non-True-Cache paths in ${CHECK_FILE}" >&2
  exit 1
fi

if [ "${callsite_count}" -ne 2 ]; then
  echo "FAIL: expected both sqlplus call sites to use sqlplus_local_connect_string in ${CHECK_FILE}" >&2
  exit 1
fi

if [ "${legacy_unquoted_sysdba_count}" -ne 0 ]; then
  echo "FAIL: found legacy unquoted SYSDBA sqlplus invocation in ${CHECK_FILE}" >&2
  exit 1
fi

echo "PASS: checkDBStatusSqlplusAuth23_26_test"
