#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
# Return codes: 0 = Database is healthy and ready to use
#               1 = Database role is neither PRIMARY nor STANDBY
#               2 = PDB is not open in required mode
#               3 = Sql Plus execution failed
#               4 = Observer is not running
#               5 = Database / PDB is mounted
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Normalize standby mode to the supported runtime values.
# Exit with a health-check failure when the requested mode is invalid.
function normalizeStandbyOpenMode() {
   STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE:-READ_ONLY}"
   STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE^^}"
   if [ "$STANDBY_OPEN_MODE" != "READ_ONLY" ] && [ "$STANDBY_OPEN_MODE" != "MOUNTED" ]; then
      echo "ERROR: STANDBY_OPEN_MODE must be READ_ONLY or MOUNTED."
      exit 3
   fi
}

# Function to check database role: either Primary or Secondary
function checkDatabaseRole() {
   # Obtain DB_ROLE using SQLPlus
   DB_ROLE=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
SELECT database_role FROM v\$database ;
exit;
EOF
)
   # Store return code from SQL*Plus
   ret=$?

   if [ $ret -eq 0 ] && [ "$DB_ROLE" != "PRIMARY" ] && [ "$DB_ROLE" != "PHYSICAL STANDBY" ] && [ "$DB_ROLE" != "SNAPSHOT STANDBY" ]; then
      exit 1
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

# Function to check whether DB is CDB or Non-CDB (YES/NO)
function checkDBType() {
   CDB_FLAG=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
SELECT CDB FROM V\$DATABASE;
exit;
EOF
)
   ret=$?

   # Trim spaces/newlines
   CDB_FLAG="$(echo "$CDB_FLAG" | tr -d '[:space:]')"

   if [ $ret -ne 0 ]; then
      exit 3
   fi

   # Validate output
   if [ "$CDB_FLAG" != "YES" ] && [ "$CDB_FLAG" != "NO" ]; then
      exit 1
   fi
}

# Function to check open_mode for Non-CDB database
function checkNonCDBOpen() {
   DB_OPEN_MODE=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
SELECT open_mode FROM v\$database;
exit;
EOF
)
   ret=$?

   # Trim spaces/newlines
   DB_OPEN_MODE="$(echo "$DB_OPEN_MODE" | xargs)"

   if [ $ret -eq 0 ] && [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$STANDBY_OPEN_MODE" = "MOUNTED" ] && [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
      return 0
   elif [ $ret -eq 0 ] && [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
      exit 5
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PRIMARY" ] && [ "$DB_OPEN_MODE" != "READ WRITE" ]; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$DB_OPEN_MODE" != "READ ONLY" ]; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "SNAPSHOT STANDBY" ] && [ "$DB_OPEN_MODE" != "READ WRITE" ]; then
      exit 2
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

# Function to check if at least one PDB is open in "READ WRITE" mode for Primary database
# Or in case of Secondary Database PDBs should be opened only in "READ ONLY" mode
function checkPDBOpen() {
   # Obtain OPEN_MODE for PDB using SQLPlus
   PDB_OPEN_MODE=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
SELECT DISTINCT open_mode FROM v\$pdbs;
exit;
EOF
)
   # Store return code from SQL*Plus
   ret=$?

   if [ $ret -eq 0 ] && echo "$PDB_OPEN_MODE" | grep -q "MOUNTED"; then
      exit 5
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PRIMARY" ] && ! echo "$PDB_OPEN_MODE" | grep -q "READ WRITE"; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$PDB_OPEN_MODE" != "READ ONLY" ]; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "SNAPSHOT STANDBY" ] && ! echo "$PDB_OPEN_MODE" | grep -q "READ WRITE"; then
      exit 2
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

# decide whether to check PDBs (CDB) or DB open_mode (Non-CDB)
# Route readiness checks through the CDB or non-CDB path.
# Preserve mounted standby handling before checking open PDB state.
function checkDBOpen() {
   checkDBType
   if [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$STANDBY_OPEN_MODE" = "MOUNTED" ]; then
      checkNonCDBOpen
      return
   fi
   if [ "$CDB_FLAG" = "YES" ]; then
      checkPDBOpen
   else
      checkNonCDBOpen
   fi
}

# Function to check that observer is running or not
function checkObserver() {
   dg_observer_status=$(dgmgrl sys@"$PRIMARY_DB_CONN_STR" "show observer" << EOF
${ORACLE_PWD}
EOF
)
   if ! echo "$dg_observer_status" | grep -q 'Observer ".*"' ; then
      exit 4
   fi
}

#############################################
################ MAIN #######################
#############################################

# Setting up ORACLE_PWD if secret file is present.
# Defaults keep existing behavior: /run/secrets/oracle_pwd
SECRET_VOLUME="${SECRET_VOLUME:-/run/secrets}"
ORACLE_PWD_SECRET_NAME="${PASSWORD_FILE:-${ORACLE_PWD_SECRET_NAME:-oracle_pwd}}"
ORACLE_PWD_SECRET_FILE="${SECRET_VOLUME}/${ORACLE_PWD_SECRET_NAME}"
if [ -e "${ORACLE_PWD_SECRET_FILE}" ]; then
   export ORACLE_PWD="$(cat "${ORACLE_PWD_SECRET_FILE}")"
fi

if [ "$DG_OBSERVER_ONLY" = "true" ]; then
   checkObserver
else
   normalizeStandbyOpenMode
   ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"
   DB_ROLE=""
   ORAENV_ASK=NO
   source oraenv
   checkDatabaseRole
   checkDBOpen
fi

exit 0
