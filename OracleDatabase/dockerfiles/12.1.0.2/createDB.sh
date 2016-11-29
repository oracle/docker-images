#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Creates an Oracle Database based on following parameters:
#              $ORACLE_SID: The Oracle SID and CDB name
#              $ORACLE_PDB: The PDB name
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 


ORACLE_SID=$1
# Check whether ORACLE_SID is passed on
if [ "$ORACLE_SID" == "" ]; then
  ORACLE_SID=ORCLCDB
fi;

ORACLE_PDB=$2
# Check whether ORACLE_PDB is passed on
if [ "$ORACLE_PDB" == "" ]; then
  ORACLE_PDB=ORCLPDB1
fi;

# Auto generate ORACLE PWD
ORACLE_PWD=`openssl rand -base64 8`
echo "ORACLE AUTO GENERATED PASSWORD FOR SYS, SYSTEM AND PDBAMIN: $ORACLE_PWD";

# Replace place holders in response file
cp $ORACLE_BASE/$CONFIG_RSP $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORACLE_BASE/dbca.rsp

# Create network related config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= {TNSNAMES, EZCONNECT, HOSTNAME}" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

" > $ORACLE_HOME/network/admin/listener.ora

# Start LISTENER and run DBCA
lsnrctl start &&
dbca -silent -responseFile $ORACLE_BASE/dbca.rsp ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log

echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" >> $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)" >> $ORACLE_HOME/network/admin/tnsnames.ora

# Remove second control file, make PDB auto open
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
EOF

# Remove temporary response file
rm $ORACLE_BASE/dbca.rsp
