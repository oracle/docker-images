#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Keep the True Cache listener externally reachable during DBCA
#              initialization so OKE service backends can pass health checks
#              before the database itself is fully open.
#

export ORACLE_SID=${ORACLE_SID:-ORCLCDB}
ORACLE_SID=${ORACLE_SID^^}
EXTENSION_SCRIPT_DIR="${EXTENSION_SCRIPT_DIR:-/opt/oracle/scripts/extensions/k8s}"
ORIGINAL_CHECK_DB_LOCK_STATUS="${EXTENSION_SCRIPT_DIR}/checkDBLockStatus.sh.orig"
FALLBACK_CHECK_DB_LOCK_STATUS="${ORACLE_BASE}/checkDBLockStatus.sh"
FALLBACK_CHECK_DB_STATUS="${ORACLE_BASE}/checkDBStatus.sh"
LISTENER_PORT="${SVC_PORT:-1521}"
CREATE_LOCK_FILE="${ORACLE_BASE}/oradata/.${ORACLE_SID}.create_lck"

same_path() {
  local lhs rhs

  lhs=$(readlink -f "$1" 2>/dev/null || printf '%s' "$1")
  rhs=$(readlink -f "$2" 2>/dev/null || printf '%s' "$2")
  [ "${lhs}" = "${rhs}" ]
}

listener_is_reachable() {
  timeout 2 bash -lc "echo > /dev/tcp/127.0.0.1/${LISTENER_PORT}" >/dev/null 2>&1
}

true_cache_is_ready() {
  local db_state

  db_state=$(sqlplus -s / as sysdba <<'SQL'
set heading off
set feedback off
set verify off
set pages 0
select database_role || '|' || open_mode from v$database;
exit
SQL
)

  [ "$(printf '%s' "${db_state}" | xargs)" = "TRUE CACHE|READ ONLY WITH APPLY" ]
}

if [ "${TRUE_CACHE}" = "true" ] && [ -f "${CREATE_LOCK_FILE}" ]; then
  if pgrep -f tnslsnr >/dev/null 2>&1 && listener_is_reachable; then
    exit 0
  fi
fi

if [ "${TRUE_CACHE}" = "true" ] && true_cache_is_ready; then
  exit 0
fi

if [ -x "${ORIGINAL_CHECK_DB_LOCK_STATUS}" ]; then
  exec "${ORIGINAL_CHECK_DB_LOCK_STATUS}" "$@"
fi

if [ "${TRUE_CACHE:-false}" != "true" ] && [ -x "${FALLBACK_CHECK_DB_LOCK_STATUS}" ]; then
  if same_path "${FALLBACK_CHECK_DB_LOCK_STATUS}" "$0"; then
    if [ -x "${FALLBACK_CHECK_DB_STATUS}" ]; then
      exec "${FALLBACK_CHECK_DB_STATUS}" "$@"
    fi
    exit 1
  fi
  exec "${FALLBACK_CHECK_DB_LOCK_STATUS}" "$@"
fi

exit 1
