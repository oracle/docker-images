#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Shuts down the Oracle Database for the base image lifecycle.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

option="${1:-immediate}"

if [ -z "$ORACLE_HOME" ]; then
  script_name=$(basename "$0")
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1
fi

if [ -z "$ORACLE_SID" ]; then
  ORACLE_SID=$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1 | head -n 1)
  export ORACLE_SID
fi

echo "Performing shutdown $option"
sqlplus / as sysdba <<EOF
   shutdown $option;
   exit;
EOF

lsnrctl stop
