#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets the password for sys, system and pdb_admin
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

ORACLE_PWD=$1
#ORACLE_SID="`grep $DB_HOME /etc/oratab | cut -d: -f1`"
#ORACLE_PDB="`ls -dl $DB_BASE/oradata/$ORACLE_SID/*/ | grep -v pdbseed | awk '{print $9}' | cut -d/ -f6`"
ORAENV_ASK=NO

ORACLE_SID=$2
ORACLE_PDB=$3

source oraenv

sqlplus / as sysdba << EOF
      ALTER USER SYS IDENTIFIED BY "$ORACLE_PWD";
      ALTER USER SYSTEM IDENTIFIED BY "$ORACLE_PWD";
      ALTER SESSION SET CONTAINER=$ORACLE_PDB;
      ALTER USER PDBADMIN IDENTIFIED BY "$ORACLE_PWD";
      exit;
EOF
