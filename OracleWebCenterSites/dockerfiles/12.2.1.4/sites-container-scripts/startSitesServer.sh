#!/bin/bash
#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: This script is used to start a Sites Managed Server.
#
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"
export SITES_CONTAINER_SCRIPTS=/u01/oracle/sites-container-scripts

. $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
WCSITES_OLD_MANAGED_HOSTNAME=$WCSITES_MANAGED_HOSTNAME

#=================================================================
function _int() {
   echo "INFO: Stopping container."
   echo "INFO: SIGINT received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $SITES_SERVER_NAME "t3://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT
   exit;
}
#=================================================================
function _term() {
   echo "INFO: Stopping container."
   echo "INFO: SIGTERM received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $SITES_SERVER_NAME "t3://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT
   exit;
}
#=================================================================
function _kill() {
   echo "INFO: SIGKILL received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $SITES_SERVER_NAME "t3://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT
   exit;
}

#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

WCSITES_MANAGED_HOSTNAME=`hostname -i`

echo Remove file $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
rm $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

echo "WCSITES_ADMIN_HOSTNAME="$WCSITES_ADMIN_HOSTNAME>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
echo "WCSITES_ADMIN_PORT="$ADMIN_PORT>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
echo "WCSITES_MANAGED_HOSTNAME="$WCSITES_MANAGED_HOSTNAME>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
echo "WCSITES_MANAGED_PORT="$WCSITES_MANAGED_PORT>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

# First Update the server in the domain
/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $SITES_CONTAINER_SCRIPTS/update_listenaddress.py $WCSITES_MANAGED_HOSTNAME $SITES_SERVER_NAME

if [ -z ${K8SENV} ]
then
    K8SENV=false
fi

if [ $K8SENV == "true" ]; then
	echo "K8SENV is true."
	sh $SITES_CONTAINER_SCRIPTS/replaceSitesK8STokens.sh	
fi

echo "Starting Sites Managed Server"
echo "=========================="

#start Sites Server
echo "tailing logs to $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/$SITES_SERVER_NAME.out"
$DOMAIN_HOME/bin/startManagedWebLogic.sh $SITES_SERVER_NAME "http://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT > $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/$SITES_SERVER_NAME.out 2>&1 &

# Tail Mananaged Server logs...
tail -900f $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/$SITES_SERVER_NAME.out &

childPID=$!
wait $childPID
