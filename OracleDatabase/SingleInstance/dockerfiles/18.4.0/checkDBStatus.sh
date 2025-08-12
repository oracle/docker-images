#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
# Return codes: 0 = PDB is open and ready to use
#               1 = PDB is not open
#               2 = Sql Plus execution failed
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ "$IGNORE_DB_STARTED_MARKER" != true ] && [ ! -f "$DB_STARTED_MARKER_FILE" ]; then
   echo "Database was not started yet." >&2
   exit 1
fi

# shellcheck disable=SC2034
ORACLE_SID="`grep $ORACLE_HOME /etc/oratab | cut -d: -f1`"
OPEN_MODE="READ WRITE"
# shellcheck disable=SC2034
ORAENV_ASK=NO
# shellcheck disable=SC1090
source oraenv

[ -f "$ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab" ] || exit 1;

# Check Oracle at least one PDB has open_mode "READ WRITE" and store it in status
status=`su -p oracle -c "sqlplus -s / as sysdba" << EOF
   set heading off;
   set pagesize 0;
   SELECT DISTINCT open_mode FROM v\\$pdbs WHERE open_mode = '$OPEN_MODE';
   exit;
EOF`

# Store return code from SQL*Plus
ret=$?

# SQL Plus execution was successful and PDB is open
if [ $ret -eq 0 ] && [ "$status" = "$OPEN_MODE" ]; then
   exit 0;
# PDB is not open
elif [ "$status" != "$OPEN_MODE" ]; then
   exit 1;
# SQL Plus execution failed
else
   exit 2;
fi;
