#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
#
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Starts the Listener and Oracle Database.
#              The ORACLE_HOME and the PATH has to be set.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Normalize standby mode to the supported startup values.
# Fail fast when the runtime config asks for an unsupported mode.
function normalizeStandbyOpenMode() {
  STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE:-READ_ONLY}"
  STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE^^}"
  if [[ "${STANDBY_OPEN_MODE}" != "READ_ONLY" && "${STANDBY_OPEN_MODE}" != "MOUNTED" ]]; then
    echo "ERROR: STANDBY_OPEN_MODE must be READ_ONLY or MOUNTED."
    exit 1
  fi
}

# Query the current database role for standby-aware startup decisions.
# Return the raw SQL*Plus output so the caller can trim it as needed.
function queryDatabaseRole() {
  sqlplus -s / as sysdba <<EOF
set heading off;
set pagesize 0;
SELECT database_role FROM v\$database;
exit;
EOF
}

# Detect whether the database is a CDB before opening PDBs.
# Return YES or NO from v$database for the caller to interpret.
function queryCDBFlag() {
  sqlplus -s / as sysdba <<EOF
set heading off;
set pagesize 0;
SELECT cdb FROM v\$database;
exit;
EOF
}

# Open the database in the role-appropriate mode after STARTUP MOUNT.
# Keep mounted physical standby databases untouched when requested.
function openDatabaseForRole() {
  local db_role="$1"
  local cdb_flag="$2"

  case "$db_role" in
    "PHYSICAL STANDBY")
      if [ "${STANDBY_OPEN_MODE}" = "MOUNTED" ]; then
        return 0
      fi
      sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER DATABASE OPEN READ ONLY;
$(if [ "$cdb_flag" = "YES" ]; then printf '%s\n' "ALTER PLUGGABLE DATABASE ALL OPEN READ ONLY;"; fi)
exit;
EOF
      ;;
    "SNAPSHOT STANDBY"|"PRIMARY")
      sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER DATABASE OPEN;
$(if [ "$cdb_flag" = "YES" ]; then printf '%s\n' "ALTER PLUGGABLE DATABASE ALL OPEN;"; fi)
exit;
EOF
      ;;
    *)
      echo "ERROR: Unsupported database role during startup: ${db_role}"
      exit 1
      ;;
  esac
}

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=$(basename "$0")
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1;
fi;

# Start Listener
lsnrctl start

if [ "${STANDBY_DB}" = "true" ]; then
  normalizeStandbyOpenMode

  sqlplus / as sysdba << EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP MOUNT;
exit;
EOF

  DB_ROLE="$(queryDatabaseRole)"
  DB_ROLE="$(echo "$DB_ROLE" | xargs)"
  CDB_FLAG="$(queryCDBFlag)"
  CDB_FLAG="$(echo "$CDB_FLAG" | tr -d '[:space:]')"

  openDatabaseForRole "$DB_ROLE" "$CDB_FLAG"
else
  # Start database
  sqlplus / as sysdba << EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP;
exit;
EOF
fi
