#!/bin/bash
#
#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
export DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME
echo "Domain Home: " $DOMAIN_HOME
echo "Managed Server Name: "  $MS_NAME
echo "NodeManager Name: "  $NM_NAME

if [ -z $ADMIN_PASSWORD ]; then
   echo "      ----> NO 'weblogic' admin password set"
   echo ""
else
   s=${ADMIN_PASSWORD}
   echo "      ----> 'weblogic' admin password: $s"
fi
sed -i -e "s|ADMIN_PASSWORD|$s|g" /u01/oracle/commonfuncs.py



# If log.nm does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer, as well Managed Server
# Otherwise, only start NM (container is being restarted)
if [ ! -f /u01/oracle/log_$MS_NAME.nm ]; then
    ADD_SERVER=1
fi

# Wait for AdminServer to become available for any subsequent operation
/u01/oracle/waitForAdminServer.sh
# Set and Start Node Manager
echo "Setting NodeManager"
if [ -z $NM_NAME ]; then
  echo "      ----> No NodeManager Name set"
  NM_NAME="Machine_$MS_NAME"
  echo "Node Manager Name: " $NM_NAME
  export $NM_NAME
fi

NM_DIR=$DOMAIN_HOME/$NM_NAME
echo "Node Manager Home for Container: " $NM_DIR
mkdir -p $NM_DIR

cp $DOMAIN_HOME/bin/startNodeManager.sh  $NM_DIR
cp -r $DOMAIN_HOME/nodemanager/* $NM_DIR

NODEMGR_HOME_STR="NODEMGR_HOME=\"$NM_DIR\""
DOMAINSFILE_STR="DomainsFile=$NM_DIR/nodemanager.domains"
NODEMGRHOME_STR="NodeManagerHome=$NM_DIR"
LOGFILE_STR="LogFile=$NM_DIR/nodemanager.log"

echo "NODEMGR_HOME_STR: " $NODEMGR_HOME_STR
echo "NODEMGRHOME_STR: " $NODEMGRHOME_STR
echo "DOMAINSFILE_STR: " $DOMAINSFILE_STR
echo "LOGFILE_STR: " $LOGFILE_STR

sed -i -e "s|NODEMGR_HOME\=.*$|$NODEMGR_HOME_STR|g" $NM_DIR/startNodeManager.sh
sed -i -e "s|DomainsFile\=.*$|$DOMAINSFILE_STR|g" $NM_DIR/nodemanager.properties
sed -i -e "s|NodeManagerHome\=.*$|$NODEMGRHOME_STR|g" $NM_DIR/nodemanager.properties
sed -i -e "s|LogFile=$|$LOGFILE_STR|g" $NM_DIR/nodemanager.properties

echo "Starting NodeManager in background..."
nohup $NM_DIR/startNodeManager.sh > /u01/oracle/log_$MS_NAME.nm 2>&1 &
echo "NodeManager started."

# Add this 'Machine' and 'ManagedServer' to the AdminServer only if 1st execution
if [ $ADD_SERVER -eq 1 ]; then
  wlst /u01/oracle/add-machine.py
  wlst /u01/oracle/add-server.py
fi

# print log
tail -f /u01/oracle/log_$MS_NAME.nm $DOMAIN_HOME/servers/$MS_NAME/logs/*.out