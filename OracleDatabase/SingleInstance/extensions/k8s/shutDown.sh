#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Apr, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Shuts down the Oracle Database.
#              The ORACLE_HOME and the PATH has to be set.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

if [ "$#" = 0 ]; then
  cat << EOF

Usage: $0 [mode]
Shutdowns the DB in the specified mode. Mode can be either of normal, immediate, transactional or abort

LICENSE UPL 1.0

Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.

EOF
exit 1
fi

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=`basename "$0"`
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1;
fi;

export ORACLE_SID=$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)
option="$1"
EXTENSION_SCRIPT_DIR="${EXTENSION_SCRIPT_DIR:-/opt/oracle/scripts/extensions/k8s}"
LOCKING_SCRIPT_PATH="${EXTENSION_SCRIPT_DIR}/${LOCKING_SCRIPT:-lock.py}"

if [ ! -f "$LOCKING_SCRIPT_PATH" ]; then
  LOCKING_SCRIPT_PATH="$ORACLE_BASE/$LOCKING_SCRIPT"
fi

if "$LOCKING_SCRIPT_PATH" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck" &> /dev/null; then
  # Exist lock held, disable exit on failed health check
  touch "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk" && sync
fi

echo "Performing shutdown $option"
# Now shutdown database
sqlplus / as sysdba << EOF
   shutdown $option;
   exit;
EOF
