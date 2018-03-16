#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
# Return codes: 0 = Database is open and ready to use
#               1 = Database is not open
#               2 = Sql Plus execution failed
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

POSITIVE_RETURN="OPEN"
ORACLE_SID="`grep $ORACLE_HOME /etc/oratab | cut -d: -f1`"

# Check Oracle DB status and store it in status
status=`su -p oracle -c "sqlplus -s / as sysdba" << EOF
   set heading off;
   set pagesize 0;
   select status from v\\$instance;
   exit;
EOF`

# Store return code from SQL*Plus
ret=$?

# SQL Plus execution was successful and database is open
if [ $ret -eq 0 ] && [ "$status" = "$POSITIVE_RETURN" ]; then
   exit 0;
# Database is not open
elif [ "$status" != "$POSITIVE_RETURN" ]; then
   exit 1;
# SQL Plus execution failed
else
   exit 2;
fi;
