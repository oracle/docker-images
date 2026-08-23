#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Ensure the True Cache readiness wrapper falls back safely
#              for non-True-Cache pods when no .orig wrapper exists.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/checkDBLockStatus.sh"

if ! grep -Fq 'FALLBACK_CHECK_DB_LOCK_STATUS="${ORACLE_BASE}/checkDBLockStatus.sh"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected primary fallback checkDBLockStatus path in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'FALLBACK_CHECK_DB_STATUS="${ORACLE_BASE}/checkDBStatus.sh"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected primary fallback checkDBStatus path in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'if [ "${TRUE_CACHE:-false}" != "true" ] && [ -x "${FALLBACK_CHECK_DB_LOCK_STATUS}" ]; then' "${WRAPPER_FILE}"; then
  echo "FAIL: expected non-True-Cache fallback guard in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'if same_path "${FALLBACK_CHECK_DB_LOCK_STATUS}" "$0"; then' "${WRAPPER_FILE}"; then
  echo "FAIL: expected self-recursion guard in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'exec "${FALLBACK_CHECK_DB_STATUS}" "$@"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected non-recursive fallback exec to checkDBStatus in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'exec "${FALLBACK_CHECK_DB_LOCK_STATUS}" "$@"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected fallback exec to primary checkDBLockStatus in ${WRAPPER_FILE}" >&2
  exit 1
fi

echo "PASS: truecacheCheckDBLockFallback_test"
