#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Swap file locks
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

EXTENSION_SCRIPT_DIR="${EXTENSION_SCRIPT_DIR:-/opt/oracle/scripts/extensions/k8s}"
LOCKING_SCRIPT_PATH="${EXTENSION_SCRIPT_DIR}/${LOCKING_SCRIPT:-lock.py}"

if [ ! -f "$LOCKING_SCRIPT_PATH" ]; then
  LOCKING_SCRIPT_PATH="$ORACLE_BASE/$LOCKING_SCRIPT"
fi

"$LOCKING_SCRIPT_PATH" --release --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.create_lck"
if ! pgrep -f "$LOCKING_SCRIPT.*--acquire.*exist_lck" > /dev/null; then
  # Acquire exist lock if not already acquired or trying. This is a blocking call
  "$LOCKING_SCRIPT_PATH" --acquire --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck" --block
fi
