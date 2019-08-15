#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Set the Oracle Connection Manager IP as remote listener in oracle DB
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Check that ORACLE_HOME is set

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

source $SCRIPT_DIR/functions.sh

sid=$1
scan_name=$2
cman_host=$3

# Check that ORACLE_SID is set
if [ -z "${sid}" ]; then
  script_name=`basename "$0"`
  error_exit  "$script_name: ERROR - ORACLE_SID is not set. Please set ORACLE_SID before invoking this script."
else
 echo "Oracle Sid : $sid"
fi;

if [ -z "${scan_name}" ]; then
  script_name=`basename "$0"`
  error_exit  "$script_name: ERROR - SCAN Name is not set. Please set SCAN Name before invoking this script."
 else
  echo " Scan name : $scan_name"
fi;

if [ -z "${cman_host}" ]; then
  script_name=`basename "$0"`
  error_exit  "$script_name: ERROR - CMAN Host Name is not set. Please set CMAN Hostname before invoking this script."
  echo "Cman Host : $cman_host"
fi;


ORACLE_SID=$($DB_HOME/bin/srvctl status database -d $sid | grep $(hostname) | awk '{ print $2 }')

echo "setting Oracle sid to  $ORACLE_SID on $(hostname)"
export ORACLE_SID=$ORACLE_SID

# Check Oracle DB status and store it in status
echo "Remote Lisetenr String : remote_listener=$scan_name:1521,(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=$cman_host)(PORT=1521))))"

status=`$DB_HOME/bin/sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
alter system set remote_listener='$scan_name:1521,(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=$cman_host)(PORT=1521))))'  scope=both;    
 alter system register;
alter system register;
alter system register;
alter system register;  
 exit;
EOF`

#echo "Stopping Oracle Database"
#$ORACLE_HOME/bin/srvctl stop database -d $sid
#echo "Starting Oracle Database"
#$ORACLE_HOME/bin/srvctl start database -d $sid
