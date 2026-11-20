#!/bin/bash
# shellcheck disable=SC2006,SC2155
# LICENSE UPL 1.0
#
# Copyright (c) 2024-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Starts the Listener and Oracle Database.
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
SWAP_LOCK_PATH="${EXTENSION_SCRIPT_DIR}/${SWAP_LOCK_FILE:-swapLocks.sh}"
SCRIPT_BASE_DIR="${SCRIPT_BASE_DIR:-/opt/oracle/scripts/base}"
CHECK_DB_FILE="${CHECK_DB_FILE:-checkDBStatus.sh}"

if [ -x "${SCRIPT_BASE_DIR}/${CHECK_DB_FILE}" ]; then
  CHECK_DB_PATH="${SCRIPT_BASE_DIR}/${CHECK_DB_FILE}"
else
  CHECK_DB_PATH="${ORACLE_BASE}/${CHECK_DB_FILE}"
fi

if [ ! -f "$SWAP_LOCK_PATH" ]; then
  SWAP_LOCK_PATH="$ORACLE_BASE/scripts/extensions/setup/$SWAP_LOCK_FILE"
fi

# Clean up any left over zombie procs from container crash, start database in nomount mode
ipcs -m | awk ' /[0-9]/ {print $2}' | xargs -n1 ipcrm -m 2> /dev/null
ipcs -s | awk ' /[0-9]/ {print $2}' | xargs -n1 ipcrm -s 2> /dev/null
for i in {1..10}; do
  sqlplus / as sysdba << EOF
   shutdown abort;
   startup nomount;
   exit;
EOF
  if pgrep -f pmon > /dev/null; then
    break
  fi
  # Sometimes DB locks of dead container are not released immediately
  echo "Waiting for $i sec(s) before restarting Oracle processes"
  sleep $i
done

# startup can get into a wait mode here
"$SWAP_LOCK_PATH"

# Start Listener
lsnrctl start

condn_sql=""
if ! pgrep -f pmon > /dev/null; then
  # if Oracle processes die for some reason by the time lock is acquired
  condn_sql="shutdown abort;
  startup nomount;
  "
fi

# Disable exit on failed health check
touch "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk" && sync

for i in {1..10}; do
  # Mount database
  sqlplus / as sysdba << EOF
   $condn_sql
   alter database mount;
   exit;
EOF

  # Get database role
  DB_ROLE=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
set feedback off;
select database_role from v\$database;
exit;
EOF
)
  DB_ROLE=$(echo "$DB_ROLE" | xargs)

  # Check if database is a CDB
  CDB_FLAG=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
set feedback off;
select cdb from v\$database;
exit;
EOF
)
  CDB_FLAG=$(echo "$CDB_FLAG" | xargs)

  # Open database based on database role
  if [ "$DB_ROLE" = "PHYSICAL STANDBY" ]; then

    # Keep standby mounted when explicitly configured in MOUNTED mode
    if [ "${STANDBY_OPEN_MODE:-READ_ONLY}" = "MOUNTED" ]; then
      sqlplus / as sysdba << EOF
       alter system register;
       exit;
EOF
    else
      sqlplus / as sysdba << EOF
       alter database open read only;
       $(if [ "$CDB_FLAG" = "YES" ]; then echo "alter pluggable database all open read only;"; fi)
       alter system register;
       exit;
EOF
    fi

  else
    sqlplus / as sysdba << EOF
     alter database open;
     $(if [ "$CDB_FLAG" = "YES" ]; then echo "alter pluggable database all open;"; fi)
     alter system register;
     exit;
EOF
  fi

  if "$CHECK_DB_PATH"; then
    # DB health is good
    echo "DB is in good health on startup"
    break
  fi

  # Sometimes DB locks of a dead container are not released immediately
  echo "Waiting for $i sec(s) before restarting Oracle processes and opening the database"
  sleep $i
done

# Enable health check exit
rm -f "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk"
