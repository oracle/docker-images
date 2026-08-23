#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: True Cache extension override for Oracle Database readiness.
#              Uses local SYSDBA connectivity when TRUE_CACHE=true.
#

normalizeStandbyOpenMode() {
   STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE:-READ_ONLY}"
   STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE^^}"
   if [ "$STANDBY_OPEN_MODE" != "READ_ONLY" ] && [ "$STANDBY_OPEN_MODE" != "MOUNTED" ]; then
      echo "ERROR: STANDBY_OPEN_MODE must be READ_ONLY or MOUNTED."
      exit 3
   fi
}

sqlplus_local_connect_string() {
   if [ "${TRUE_CACHE:-false}" = "true" ]; then
      echo "/ as sysdba"
   else
      echo "/"
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

checkDatabaseRole() {
   DB_STATUS=$("${SQLPLUS_BIN}" -s "$(sqlplus_local_connect_string)" << EOF
set heading off;
set pagesize 0;
SELECT database_role || '|' || open_mode FROM v\$database ;
exit;
EOF
)
   ret=$?
   DB_ROLE=$(echo "$DB_STATUS" | cut -d'|' -f1 | xargs)
   DB_OPEN_MODE=$(echo "$DB_STATUS" | cut -d'|' -f2- | xargs)

   if [ $ret -eq 0 ] && [ "$DB_ROLE" != "PRIMARY" ] && [ "$DB_ROLE" != "PHYSICAL STANDBY" ] && [ "$DB_ROLE" != "TRUE CACHE" ] && [ "$DB_ROLE" != "SNAPSHOT STANDBY" ]; then
      exit 1
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

checkDBType() {
   CDB_FLAG=$("${SQLPLUS_BIN}" -s "$(sqlplus_local_connect_string)" << EOF
set heading off;
set pagesize 0;
SELECT CDB FROM V\$DATABASE;
exit;
EOF
)
   ret=$?
   CDB_FLAG="$(echo "$CDB_FLAG" | tr -d '[:space:]')"

   if [ $ret -ne 0 ]; then
      exit 3
   fi

   if [ "$CDB_FLAG" != "YES" ] && [ "$CDB_FLAG" != "NO" ]; then
      exit 1
   fi
}

checkNonCDBOpen() {
   DB_OPEN_MODE=$("${SQLPLUS_BIN}" -s "$(sqlplus_local_connect_string)" << EOF
set heading off;
set pagesize 0;
SELECT open_mode FROM v\$database;
exit;
EOF
)
   ret=$?
   DB_OPEN_MODE="$(echo "$DB_OPEN_MODE" | xargs)"

   if [ $ret -eq 0 ] && [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$STANDBY_OPEN_MODE" = "MOUNTED" ] && [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
      return 0
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "TRUE CACHE" ] && [ "$DB_OPEN_MODE" = "READ ONLY WITH APPLY" ]; then
      return 0
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "TRUE CACHE" ] && [ "$DB_OPEN_MODE" = "READ ONLY" ]; then
      exit 5
   elif [ $ret -eq 0 ] && [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
      exit 5
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PRIMARY" ] && [ "$DB_OPEN_MODE" != "READ WRITE" ]; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$DB_OPEN_MODE" != "READ ONLY" ]; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "SNAPSHOT STANDBY" ] && [ "$DB_OPEN_MODE" != "READ WRITE" ]; then
      exit 2
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "TRUE CACHE" ]; then
      exit 2
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

checkPDBOpen() {
   if [ "$DB_ROLE" = "PHYSICAL STANDBY" ] && [ "$STANDBY_OPEN_MODE" = "MOUNTED" ]; then
      if [ "$DB_OPEN_MODE" = "MOUNTED" ]; then
         return 0
      fi
      exit 5
   fi

   if [ "$DB_ROLE" = "TRUE CACHE" ]; then
      if [ "$DB_OPEN_MODE" = "READ ONLY WITH APPLY" ]; then
         return 0
      elif [ "$DB_OPEN_MODE" = "MOUNTED" ] || [ "$DB_OPEN_MODE" = "READ ONLY" ]; then
         exit 5
      else
         exit 2
      fi
   fi

   PDB_OPEN_MODE=$("${SQLPLUS_BIN}" -s "$(sqlplus_local_connect_string)" << EOF
set heading off;
set pagesize 0;
SELECT DISTINCT open_mode FROM v\$pdbs;
exit;
EOF
)
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

checkDBOpen() {
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

checkObserver() {
   dg_observer_status=$(dgmgrl sys@"$PRIMARY_DB_CONN_STR" "show observer" << EOF
${ORACLE_PWD}
EOF
)
   if ! echo "$dg_observer_status" | grep -q 'Observer ".*"' ; then
      exit 4
   fi
}

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
   ORAENV_ASK=NO
   # shellcheck source=/dev/null
   source oraenv <<< "${ORACLE_SID}" >/dev/null 2>&1 || true
   resolve_sqlplus_bin
   checkDatabaseRole
   checkDBOpen
fi
exit 0
