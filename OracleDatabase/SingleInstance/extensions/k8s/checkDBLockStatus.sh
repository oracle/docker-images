#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Checks the status of Oracle Database and Locks
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

export ORACLE_SID=${ORACLE_SID:-ORCLCDB}
ORACLE_SID=${ORACLE_SID^^}

if [ "$DG_OBSERVER_ONLY" = "true" ]; then
  "$ORACLE_BASE/$CHECK_DB_FILE"
  exit $?
elif "$ORACLE_BASE/$LOCKING_SCRIPT" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.create_lck"; then
  exit 1  # create lock held, DB is still initializing
elif ! "$ORACLE_BASE/$LOCKING_SCRIPT" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck"; then
  exit 1 # exist lock not held, DB is still initializing
elif "$ORACLE_BASE/$CHECK_DB_FILE"; then
  # DB health is good
  exit 0
elif test -f "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk"; then
  exit 1 # Skip health check
elif pgrep -f pmon > /dev/null; then
  # DB procs detected
  exit 1
else
  # No DB procs detected
  "$ORACLE_BASE/$LOCKING_SCRIPT" --release --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck"
  # Kill the process that keeps the container alive
  pkill -9 -f "tail.*alert"
fi
