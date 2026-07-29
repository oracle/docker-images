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

# Start database in nomount mode first
sqlplus / as sysdba << EOF
   startup nomount;
   exit;
EOF

# First check if exist lock is held
if ! "$LOCKING_SCRIPT_PATH" --check --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.exist_lck" &> /dev/null; then
  exit 1 # exist lock not held, don't mount datafiles
fi

# Mount database
sqlplus / as sysdba << EOF
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

# Now remove the chk file
rm -f "$ORACLE_BASE/oradata/.${ORACLE_SID}.nochk"