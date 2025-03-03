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

# Function to check database role: either Primary or Secondary
checkDatabaseRole() {
   # Obtain DB_ROLE using SQLPlus
   DB_ROLE=$(sqlplus -s / << EOF
set heading off;
set pagesize 0;
SELECT database_role FROM v\$database ;
exit;
EOF
)
   # Store return code from SQL*Plus
   ret=$?

   if [ $ret -eq 0 ] && [ "$DB_ROLE" != "PRIMARY" ] && [ "$DB_ROLE" != "PHYSICAL STANDBY" ] && [ "$DB_ROLE" != "TRUE CACHE" ]; then
      exit 1
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

# Function to check if at least one PDB is open in "READ WRITE" mode for Primary database
# Or in case of Secondary Database PDBs should be opened only in "READ ONLY" mode 
checkPDBOpen() {
   # Obtain OPEN_MODE for PDB using SQLPlus
   PDB_OPEN_MODE=$(sqlplus -s / << EOF
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
   elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "TRUE CACHE" ] && [ "$PDB_OPEN_MODE" != "READ ONLY" ]; then
      exit 2
   elif [ $ret -ne 0 ]; then
      exit 3
   fi
}

# Function to check that observer is running or not
checkObserver() {
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

if [ "$IGNORE_DB_STARTED_MARKER" != true ] && [ ! -f "$DB_STARTED_MARKER_FILE" ]; then
   echo "Database was not started yet." >&2
   exit 1
fi

ORACLE_PWD=$($ORACLE_BASE/$DECRYPT_PWD_FILE)
export ORACLE_PWD

# Sanitizing env for FREE Database
if [ "${ORACLE_SID}" = "FREE" ]; then
   unset DG_OBSERVER_ONLY
fi

if [ "$DG_OBSERVER_ONLY" = "true" ]; then
   checkObserver
else
   ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"
   DB_ROLE=""
   # shellcheck disable=SC2034
   ORAENV_ASK=NO
   # shellcheck source=/dev/null
   source oraenv
   checkDatabaseRole
   checkPDBOpen
fi
exit 0

