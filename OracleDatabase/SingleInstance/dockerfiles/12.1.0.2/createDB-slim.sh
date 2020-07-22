#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Creates an Oracle Database based on following parameters:
#              $ORACLE_SID: The Oracle SID and CDB name
#              $ORACLE_PDB: The PDB name
#              $ORACLE_PWD: The Oracle password
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -e

# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCLCDB}

# Check whether ORACLE_PDB is passed on
export ORACLE_PDB=${2:-ORCLPDB1}

# Create network related config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" > $ORACLE_HOME/network/admin/listener.ora

# Start LISTENER and run DBCA
lsnrctl start

echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_PDB= 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = $ORACLE_PDB)
    )
  )" >> $ORACLE_HOME/network/admin/tnsnames.ora

# make some required directories it not exists
mkdir -p $ORACLE_BASE/oradata/$ORACLE_SID
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
mkdir -p $ORACLE_BASE/fast_recovery_area

# Check init-db.tar format
if [ -f /opt/oracle/scripts/setup/init-db.tar ]; then
  (cd /opt/oracle/scripts/setup;tar xf init-db.tar)
fi;

# Check init-db.tar.gz format
if [ -f /opt/oracle/scripts/setup/init-db.tar.gz ]; then
  (cd /opt/oracle/scripts/setup;tar xfz init-db.tar.gz)
fi;

# Check whether database already exists
if [ -f /opt/oracle/scripts/setup/spfile.bks ]; then
  # start process of restore from rman full backup, first spfile
  rman target /<<EOF
startup nomount force;
restore spfile from '/opt/oracle/scripts/setup/spfile.bks';
shutdown immediate;
startup nomount;
exit;
EOF

  # begin restore if control files are present
  if [ -f /opt/oracle/scripts/setup/control.bks ]; then
    rman target /<<EOF
restore controlfile from '/opt/oracle/scripts/setup/control.bks';
alter database mount;
restore database;
report schema;
recover database noredo;
alter database open resetlogs;
exit;
EOF
  fi;

  # reset password for SYS
  orapwd file=$ORACLE_HOME/dbs/orapw$ORACLE_SID password=$ORACLE_PWD ignorecase=n force=y format=12
  chown oracle:oinstall $ORACLE_HOME/dbs/orapw$ORACLE_SID
  echo "$ORACLE_SID:$ORACLE_HOME:N" >> /etc/oratab
fi;
