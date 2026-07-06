#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Starts the Oracle Database.
#              The ORACLE_HOME and the PATH has to be set.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=`basename "$0"`
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1;
fi;

export ORACLE_SID=$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)
EXTENSION_SCRIPT_DIR="${EXTENSION_SCRIPT_DIR:-/opt/oracle/scripts/extensions/k8s}"
LOCKING_SCRIPT_PATH="${EXTENSION_SCRIPT_DIR}/${LOCKING_SCRIPT:-lock.py}"

if [ ! -f "$LOCKING_SCRIPT_PATH" ]; then
  LOCKING_SCRIPT_PATH="$ORACLE_BASE/$LOCKING_SCRIPT"
fi

# Start database in nomount mode firt
sqlplus / as sysdba << EOF
   startup nomount;
   exit;
EOF

# First check if exist lock is held
if ! "$LOCKING_SCRIPT_PATH" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck" &> /dev/null; then
  exit 1 # exist lock not held, don't mount datafiles
fi

# Start database
sqlplus / as sysdba << EOF
   alter database mount;
   alter database open;
   alter system register;
   exit;
EOF

# Now remove the chk file
rm -f "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk"
