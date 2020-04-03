#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
# Return codes: 0 = CDB is open and ready to use
#               1 = Sql Plus execution failed
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

ORACLE_SID="`grep $ORACLE_HOME /etc/oratab | cut -d: -f1`"
ORAENV_ASK=NO
source oraenv

status=`sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
   exit;
EOF`

# Store return code from SQL*Plus
ret=$?

# SQL Plus execution was successful
if [ $ret -eq 0 ]; then
   exit 0;
# SQL Plus execution failed
else
   exit 1;
fi;
