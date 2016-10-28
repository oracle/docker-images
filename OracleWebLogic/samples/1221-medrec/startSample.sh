#!/bin/sh
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
sample=$1
WORK_DIR=/u01/oracle/wlserver/samples/server/medrec/
FILE=/u01/oracle/user_projects/domains/medrec/config/jdbc/MedRec-jdbc.xml

#check if medrec is already deployed
if [ -f $FILE ]; then
   echo "Start AdminServer"
   cd $WORK_DIR/install/non-mt-single-server
   ant start
else
   # Define default command to create medrec domain
   ant $sample
   mkdir -p /u01/oracle/user_projects/domains/medrec/servers/AdminServer/logs/
   touch /u01/oracle/user_projects/domains/medrec/servers/AdminServer/logs/AdminServer.log
fi

tail -f /u01/oracle/user_projects/domains/medrec/servers/AdminServer/logs/AdminServer.log
