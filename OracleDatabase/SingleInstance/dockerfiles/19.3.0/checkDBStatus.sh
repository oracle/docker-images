#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2155
# shellcheck disable=SC1090,SC2034
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
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

# Convert a string to a normalized token:
#   - uppercase
#   - trim leading/trailing whitespace
#   - collapse spaces to underscores
normalize_mode() {
   echo "$1" | tr '[:lower:]' '[:upper:]' | xargs | tr ' ' '_'
}

# Normalize the standby expectation.
# Supported values:
#   AUTO
#   MOUNTED
#   READ_ONLY
#   READ_ONLY_WITH_APPLY
#
# AUTO means "accept any healthy standby state" and is the default.
function normalizeStandbyOpenMode() {
   STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE:-AUTO}"
   STANDBY_OPEN_MODE="$(normalize_mode "$STANDBY_OPEN_MODE")"

   case "$STANDBY_OPEN_MODE" in
      AUTO|MOUNTED|READ_ONLY|READ_ONLY_WITH_APPLY)
         ;;
      *)
         echo "ERROR: STANDBY_OPEN_MODE must be AUTO, MOUNTED, READ ONLY, or READ ONLY WITH APPLY."
         exit 3
         ;;
   esac
}

# Query database state once and keep the result for the rest of the checks.
function queryDatabaseState() {
   local db_state

   db_state=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
set feedback off;
set verify off;
set echo off;
whenever sqlerror exit 3;
SELECT database_role || '|' || open_mode || '|' || cdb FROM v\$database;
exit;
EOF
)
   ret=$?

   if [ $ret -ne 0 ]; then
      exit 3
   fi

   db_state="$(echo "$db_state" | tr -d '\r' | sed '/^[[:space:]]*$/d' | tail -n 1 | xargs)"
   IFS='|' read -r DB_ROLE_RAW DB_OPEN_MODE_RAW CDB_FLAG_RAW <<< "$db_state"

   DB_ROLE="$(normalize_mode "$DB_ROLE_RAW")"
   DB_OPEN_MODE="$(normalize_mode "$DB_OPEN_MODE_RAW")"
   CDB_FLAG="$(normalize_mode "$CDB_FLAG_RAW")"

   if [ "$DB_ROLE" != "PRIMARY" ] && [ "$DB_ROLE" != "PHYSICAL_STANDBY" ] && [ "$DB_ROLE" != "SNAPSHOT_STANDBY" ]; then
      exit 1
   fi

   if [ "$CDB_FLAG" != "YES" ] && [ "$CDB_FLAG" != "NO" ]; then
      exit 1
   fi
}

# Validate the database open mode based on role.
function checkDatabaseOpenMode() {
   case "$DB_ROLE" in
      PRIMARY)
         if [ "$DB_OPEN_MODE" != "READ_WRITE" ]; then
            echo "ERROR: PRIMARY database must be READ WRITE. Actual mode: ${DB_OPEN_MODE}" >&2
            exit 2
         fi
         ;;

      PHYSICAL_STANDBY)
         case "$STANDBY_OPEN_MODE" in
            AUTO)
               case "$DB_OPEN_MODE" in
                  MOUNTED|READ_ONLY|READ_ONLY_WITH_APPLY)
                     ;;
                  *)
                     echo "ERROR: Invalid physical standby mode. Actual mode: ${DB_OPEN_MODE}" >&2
                     exit 2
                     ;;
               esac
               ;;

            READ_ONLY)
               # READ ONLY WITH APPLY is also considered a healthy
               # read-only standby state.
               case "$DB_OPEN_MODE" in
                  READ_ONLY|READ_ONLY_WITH_APPLY)
                     ;;
                  *)
                     echo "ERROR: Expected READ ONLY or READ ONLY WITH APPLY. Actual mode: ${DB_OPEN_MODE}" >&2
                     exit 2
                     ;;
               esac
               ;;

            READ_ONLY_WITH_APPLY)
               if [ "$DB_OPEN_MODE" != "READ_ONLY_WITH_APPLY" ]; then
                  echo "ERROR: Expected READ ONLY WITH APPLY. Actual mode: ${DB_OPEN_MODE}" >&2
                  exit 2
               fi
               ;;

            MOUNTED)
               if [ "$DB_OPEN_MODE" != "MOUNTED" ]; then
                  echo "ERROR: Expected MOUNTED. Actual mode: ${DB_OPEN_MODE}" >&2
                  exit 2
               fi
               ;;

            *)
               echo "ERROR: Unsupported STANDBY_OPEN_MODE: ${STANDBY_OPEN_MODE}" >&2
               exit 2
               ;;
         esac
         ;;

      SNAPSHOT_STANDBY)
         if [ "$DB_OPEN_MODE" != "READ_WRITE" ]; then
            echo "ERROR: SNAPSHOT STANDBY must be READ WRITE. Actual mode: ${DB_OPEN_MODE}" >&2
            exit 2
         fi
         ;;

      *)
         echo "ERROR: Unsupported database role: ${DB_ROLE}" >&2
         exit 1
         ;;
   esac
}

# Validate PDB state for a CDB.
# For PRIMARY and SNAPSHOT STANDBY, PDBs must be READ WRITE.
# For PHYSICAL STANDBY:
#   - if the CDB is mounted, PDB checks are skipped
#   - if the CDB is open read only / read only with apply, PDBs must be READ ONLY
function checkPDBOpen() {
   local expected_pdb_mode="$1"
   local pdb_modes

   pdb_modes=$(sqlplus -s / as sysdba << EOF
set heading off;
set pagesize 0;
set feedback off;
set verify off;
set echo off;
whenever sqlerror exit 3;
SELECT DISTINCT open_mode FROM v\$pdbs WHERE name <> 'PDB\$SEED';
exit;
EOF
)
   ret=$?

   if [ $ret -ne 0 ]; then
      exit 3
   fi

   pdb_modes="$(echo "$pdb_modes" | tr -d '\r' | sed '/^[[:space:]]*$/d')"

   # No user PDBs to validate.
   if [ -z "$pdb_modes" ]; then
      return 0
   fi

   # Fail if any PDB is not in the expected mode.
   if echo "$pdb_modes" | grep -vFx "$expected_pdb_mode" >/dev/null; then
      exit 2
   fi
}

# Decide whether to check PDBs (CDB) or just the database open mode (Non-CDB).
function checkDBOpen() {
   checkDatabaseOpenMode

   if [ "$CDB_FLAG" = "NO" ]; then
      return 0
   fi

   case "$DB_ROLE" in
      PRIMARY|SNAPSHOT_STANDBY)
         checkPDBOpen "READ WRITE"
         ;;
      PHYSICAL_STANDBY)
         if [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
            return 0
         fi
         checkPDBOpen "READ ONLY"
         ;;
      *)
         exit 1
         ;;
   esac
}

# Function to check if observer is running
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
   DB_OPEN_MODE=""
   CDB_FLAG=""
   ORAENV_ASK=NO
   source oraenv
   queryDatabaseState
   checkDBOpen
fi

exit 0
