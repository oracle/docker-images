#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
# Description: Repair persisted SIDB listener bind addresses after pod recreation.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

set -euo pipefail

ORACLE_BASE="${ORACLE_BASE:-/opt/oracle}"
ORACLE_HOME="${ORACLE_HOME:-/opt/oracle/product/26ai/dbhome_1}"
ORACLE_SID="${ORACLE_SID:-$(awk -F: -v oracle_home="${ORACLE_HOME}" '$2 == oracle_home { print $1; exit }' /etc/oratab 2>/dev/null || true)}"
ORACLE_SID="${ORACLE_SID^^}"
LISTENER_BIND_HOST="${LISTENER_BIND_HOST:-0.0.0.0}"

if [ -z "${ORACLE_SID}" ]; then
  exit 0
fi

LISTENER_FILE="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/listener.ora"
if [ ! -f "${LISTENER_FILE}" ]; then
  exit 0
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT
awk -v host="${LISTENER_BIND_HOST}" '{ gsub(/\(HOST[[:space:]]*=[[:space:]]*[^)[:space:]]+\)/, "(HOST=" host ")"); print }' "${LISTENER_FILE}" > "${TMP_FILE}"

if cmp -s "${LISTENER_FILE}" "${TMP_FILE}"; then
  exit 0
fi

mv "${TMP_FILE}" "${LISTENER_FILE}"
trap - EXIT
echo "INFO: repaired listener HOST entries to bind address ${LISTENER_BIND_HOST}"
# Startup may call this before the listener exists. Reconciliation may call it
# while the listener is running, so reload first and restart if reload fails.
if ! lsnrctl reload >/dev/null 2>&1; then
  lsnrctl stop >/dev/null 2>&1 || true
  lsnrctl start >/dev/null 2>&1 || echo "WARNING: listener restart deferred"
fi
