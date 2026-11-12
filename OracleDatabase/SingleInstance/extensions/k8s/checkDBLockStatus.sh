#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Checks the status of Oracle Database and Locks
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

export ORACLE_SID=${ORACLE_SID:-ORCLCDB}
ORACLE_SID=${ORACLE_SID^^}
EXTENSION_SCRIPT_DIR="${EXTENSION_SCRIPT_DIR:-/opt/oracle/scripts/extensions/k8s}"
LOCKING_SCRIPT_PATH="${EXTENSION_SCRIPT_DIR}/${LOCKING_SCRIPT:-lock.py}"
SCRIPT_BASE_DIR="${SCRIPT_BASE_DIR:-/opt/oracle/scripts/base}"
CHECK_DB_FILE="${CHECK_DB_FILE:-checkDBStatus.sh}"
PMON_MISSING_FILE="/tmp/.${ORACLE_SID}.pmon_missing_since"
PMON_GRACE_SECONDS="${PMON_GRACE_SECONDS:-300}"

if [ -x "${SCRIPT_BASE_DIR}/${CHECK_DB_FILE}" ]; then
  CHECK_DB_PATH="${SCRIPT_BASE_DIR}/${CHECK_DB_FILE}"
else
  CHECK_DB_PATH="${ORACLE_BASE}/${CHECK_DB_FILE}"
fi

if [ ! -f "$LOCKING_SCRIPT_PATH" ]; then
  LOCKING_SCRIPT_PATH="$ORACLE_BASE/$LOCKING_SCRIPT"
fi

if [ "$DG_OBSERVER_ONLY" = "true" ]; then
  "$CHECK_DB_PATH"
  exit $?
elif "$LOCKING_SCRIPT_PATH" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.create_lck"; then
  exit 1  # create lock held, DB is still initializing
elif ! "$LOCKING_SCRIPT_PATH" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck"; then
  exit 1 # exist lock not held, DB is still initializing
elif "$CHECK_DB_PATH"; then
  # DB health is good
  rm -f "$PMON_MISSING_FILE"
  exit 0
elif test -f "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk"; then
  rm -f "$PMON_MISSING_FILE"
  exit 1 # Skip health check
elif pgrep -f "[o]ra_pmon_${ORACLE_SID}" > /dev/null; then
  # DB procs detected
  rm -f "$PMON_MISSING_FILE"
  exit 1
else
  # No DB procs detected
  now=$(date +%s)

  if [ ! -f "$PMON_MISSING_FILE" ]; then
    echo "$now" > "$PMON_MISSING_FILE"
    echo "PMON is temporarily unavailable; starting ${PMON_GRACE_SECONDS}s grace period."
    exit 1
  fi

  missing_since=$(cat "$PMON_MISSING_FILE" 2>/dev/null || echo "$now")
  elapsed=$((now - missing_since))

  if [ "$elapsed" -lt "$PMON_GRACE_SECONDS" ]; then
    echo "PMON unavailable for ${elapsed}s; waiting for ${PMON_GRACE_SECONDS}s grace period."
    exit 1
  fi

  echo "PMON unavailable for ${elapsed}s; restarting the container."
  rm -f "$PMON_MISSING_FILE"

  "$LOCKING_SCRIPT_PATH" --release --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck"
  # Kill the process that keeps the container alive
  pkill -9 -f "tail.*alert"
fi
