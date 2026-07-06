#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
# Return codes: 0 = Database is healthy and ready to use
#               1 = Database role is neither PRIMARY nor STANDBY
#               2 = PDB is not open in required mode
#               3 = Sql Plus execution failed
#               4 = Observer is not running
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

resolve_sqlplus_bin() {
   if [ -n "${ORACLE_HOME:-}" ] && [ -x "${ORACLE_HOME}/bin/sqlplus" ]; then
      SQLPLUS_BIN="${ORACLE_HOME}/bin/sqlplus"
      export ORACLE_HOME PATH="${ORACLE_HOME}/bin:${PATH}"
      return 0
   fi

   if [ -n "${ORACLE_SID:-}" ]; then
      ORACLE_HOME="$(awk -F: -v sid="${ORACLE_SID}" '$1 == sid { print $2; exit }' /etc/oratab)"
   fi

   if [ -z "${ORACLE_HOME:-}" ] || [ ! -x "${ORACLE_HOME}/bin/sqlplus" ]; then
      echo "ERROR: Unable to resolve ORACLE_HOME/sqlplus for SID ${ORACLE_SID:-unset}."
      exit 3
   fi

   SQLPLUS_BIN="${ORACLE_HOME}/bin/sqlplus"
   export ORACLE_HOME PATH="${ORACLE_HOME}/bin:${PATH}"
}

# Function to check database role: either Primary or Secondary
function checkDatabaseRole() {
   # Obtain DB_ROLE using SQLPlus
   DB_STATUS=$("${SQLPLUS_BIN}" -s / << EOF
set heading off;
set pagesize 0;
SELECT database_role || '|' || open_mode FROM v\$database ;
exit;
EOF
)
   # Store return code from SQL*Plus
   ret=$?
   DB_ROLE=$(echo "$DB_STATUS" | cut -d'|' -f1 | xargs)
   DB_OPEN_MODE=$(echo "$DB_STATUS" | cut -d'|' -f2- | xargs)

   if [ $ret -eq 0 ] && [ "$DB_ROLE" != "PRIMARY" ] && [ "$DB_ROLE" != "PHYSICAL STANDBY" ] && [ "$DB_ROLE" != "SNAPSHOT STANDBY" ] && [ "$DB_ROLE" != "TRUE CACHE" ]; then
      exit 1
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

# Function to check if at least one PDB is open in "READ WRITE" mode for Primary database
# Or in case of Secondary Database PDBs should be opened only in "READ ONLY" mode
function checkPDBOpen() {
   if [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$STANDBY_OPEN_MODE" = "MOUNTED" ]; then
      if [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
         return 0
      fi
      exit 5
   fi

   if [ "$DB_ROLE" = "TRUE CACHE" ]; then
      if [ "$DB_OPEN_MODE" = "READ ONLY WITH APPLY" ]; then
         return 0
      else
         exit 2
      fi
   fi

   # Obtain OPEN_MODE for PDB using SQLPlus
   PDB_OPEN_MODE=$("${SQLPLUS_BIN}" -s / << EOF
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
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "TRUE CACHE" ] && [ "$PDB_OPEN_MODE" != "READ ONLY" ]; then
      exit 2
   elif [ $ret -ne 0 ]; then
      exit 3
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

SCRIPT_BASE_DIR="${SCRIPT_BASE_DIR:-/opt/oracle/scripts/base}"
DECRYPT_PWD_FILE="${DECRYPT_PWD_FILE:-decryptPassword.sh}"

if [ -x "${SCRIPT_BASE_DIR}/${DECRYPT_PWD_FILE}" ]; then
   DECRYPT_PWD_PATH="${SCRIPT_BASE_DIR}/${DECRYPT_PWD_FILE}"
elif [ -x "${ORACLE_BASE}/${DECRYPT_PWD_FILE}" ]; then
   DECRYPT_PWD_PATH="${ORACLE_BASE}/${DECRYPT_PWD_FILE}"
else
   DECRYPT_PWD_PATH=""
fi

if [ -n "${DECRYPT_PWD_PATH}" ]; then
   export ORACLE_PWD="$("${DECRYPT_PWD_PATH}")"
fi

# Sanitizing env for FREE Database
if [ "${ORACLE_SID}" = "FREE" ]; then
   unset DG_OBSERVER_ONLY
fi

if [ "$DG_OBSERVER_ONLY" = "true" ]; then
   checkObserver
else
   normalizeStandbyOpenMode
   if [ -z "${ORACLE_SID:-}" ]; then
      ORACLE_SID="$(awk -F: 'NF >= 2 && $1 !~ /^#/ { print $1; exit }' /etc/oratab)"
   fi
   resolve_sqlplus_bin
   DB_ROLE=""
   DB_OPEN_MODE=""
   # shellcheck disable=SC2034
   ORAENV_ASK=NO
   # shellcheck source=/dev/null
   source oraenv <<< "${ORACLE_SID}" >/dev/null 2>&1 || true
   resolve_sqlplus_bin
   checkDatabaseRole
   checkPDBOpen
fi
exit 0
