#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the status of Oracle Database.
#              The ORACLE_HOME, ORACLE_SID and the PATH has to be set.
# 
# Return codes: 0 = Database is open and ready to use
#               1 = Database is not open
#               2 = Sql Plus execution failed
#               3 = Environment variables aren't set
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=`basename "$0"`
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 3;
fi;

# Check that ORACLE_SID is set
if [ "$ORACLE_SID" == "" ]; then
  script_name=`basename "$0"`
  echo "$script_name: ERROR - ORACLE_SID is not set. Please set ORACLE_SID before invoking this script."
  exit 3;
fi;

# Check Oracle DB status and store it in status
status=`sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
   select status from v\\$instance;
   exit;
EOF`

# Store return code from SQL*Plus
ret=$?

# SQL Plus execution was successful and database is open
if [ $ret -eq 0 ] && [ "$status" = "OPEN" ]; then
   exit 0;
# Database is not open
elif [ "$status" != "OPEN" ]; then
   exit 1;
# SQL Plus execution failed
else
   exit 2;
fi;
