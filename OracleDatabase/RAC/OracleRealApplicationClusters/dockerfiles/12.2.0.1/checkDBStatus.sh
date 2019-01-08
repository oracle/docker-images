#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Checks the status of Oracle Database.
#              The ORACLE_HOME, ORACLE_SID and the PATH has to be set.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Check that ORACLE_HOME is set

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

source $SCRIPT_DIR/functions.sh

sid=$1

# Check that ORACLE_SID is set
if [ -z "${sid}" ]; then
  script_name=`basename "$0"`
  error_exit  "$script_name: ERROR - ORACLE_SID is not set. Please set ORACLE_SID before invoking this script."
  exit 3;
fi;

ORACLE_SID=$($DB_HOME/bin/srvctl status database -d $sid | grep $(hostname) | awk '{ print $2 }')

echo "Checking $ORACLE_SID on $(hostname)"
export ORACLE_SID=$ORACLE_SID

# Check Oracle DB status and store it in status
status=`$DB_HOME/bin/sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
   select status from v\\$instance;
   exit;
EOF`

echo $status > /tmp/db_status.txt
