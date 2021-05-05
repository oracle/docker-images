#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2020
# Author: abhishek.by.kumar@oracle.com
# Description: Checks for the status of standby database.
# Return codes: 0 = Database is ready to use
#               1 = Unsuccessful
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

ORACLE_SID="`grep $ORACLE_HOME /etc/oratab | cut -d: -f1`"
ORAENV_ASK=NO
source oraenv

# Check Oracle at least one PDB has open_mode "READ WRITE" and store it in status
status=`sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
   SELECT database_role, open_mode FROM v\\$database ;
   exit;
EOF`

DB_ROLE=`echo ${status} | tr -s " " | cut -d " " -f 1`
OPEN_MODE=`echo ${status} | tr -s " " | cut -d " " -f 2`

# Store return code from SQL*Plus
ret=$?

# SQL Plus execution was successful and DB is in standby mode
if [ $ret -eq 0 ] && [ "$DB_ROLE" = "STANDBY" ] && [ "$OPEN_MODE" = "READ ONLY" ]; then
   exit 0;
# SQL Plus execution was successful and DB is in primary mode
elif [ $ret -eq 0 ] && [ "$DB_ROLE" = "PRIMARY" ] && [ "$OPEN_MODE" = "READ WRITE" ]; then
   exit 0;
# SQL Plus execution failed
else
   exit 1;
fi;