#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
# Return codes: 0 = PDB is open and ready to use
#               1 = PDB is not open
#               2 = Sql Plus execution failed
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

ORACLE_SID="`grep $ORACLE_HOME /etc/oratab | cut -d: -f1`"
ORACLE_PDB="`ls -dl $ORACLE_BASE/oradata/$ORACLE_SID/*/ | grep -v pdbseed | awk '{print $9}' | cut -d/ -f6`"
POSITIVE_RETURN="READ WRITE"
ORAENV_ASK=NO
source oraenv

# Check Oracle DB status and store it in status
status=`sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
   SELECT open_mode FROM v\\$pdbs WHERE UPPER(name) = UPPER('$ORACLE_PDB');
   exit;
EOF`

# Store return code from SQL*Plus
ret=$?

# SQL Plus execution was successful and PDB is open
if [ $ret -eq 0 ] && [ "$status" = "$POSITIVE_RETURN" ]; then
   exit 0;
# PDB is not open
elif [ "$status" != "$POSITIVE_RETURN" ]; then
   exit 1;
# SQL Plus execution failed
else
   exit 2;
fi;
