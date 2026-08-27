#!/bin/bash
# shellcheck disable=SC2034,SC2155
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

checkDatabaseRole() {
   DB_STATUS=$(sqlplus -s "$(sqlplus_local_connect_string)" << EOF
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

   PDB_OPEN_MODE=$(sqlplus -s "$(sqlplus_local_connect_string)" << EOF
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

checkObserver() {
   dg_observer_status=$(dgmgrl sys@"$PRIMARY_DB_CONN_STR" "show observer" << EOF
${ORACLE_PWD}
EOF
)
   if ! echo "$dg_observer_status" | grep -q 'Observer ".*"' ; then
      exit 4
   fi
}

export ORACLE_PWD=$($ORACLE_BASE/$DECRYPT_PWD_FILE)

if [ "${ORACLE_SID}" = "FREE" ]; then
   unset DG_OBSERVER_ONLY
fi

if [ "$DG_OBSERVER_ONLY" = "true" ]; then
   checkObserver
else
   normalizeStandbyOpenMode
   ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"
   DB_ROLE=""
   DB_OPEN_MODE=""
   ORAENV_ASK=NO
   # shellcheck source=/dev/null
   source oraenv
   checkDatabaseRole
   checkPDBOpen
fi
exit 0
