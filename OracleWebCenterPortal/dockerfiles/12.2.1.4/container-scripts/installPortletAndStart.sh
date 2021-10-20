#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
function validate_parameter {
  name=$1
  value=$2
  if [ -z $value ]
  then
    echo "ERROR: Please set '$name' in configmap."
    echo ""
    exit 1
  fi
}

if [ -z ${KEEP_CONTAINER_ALIVE} ]
then
   # by default we always keep this flag ON
   export KEEP_CONTAINER_ALIVE="true"
fi

export vol_name=u01
export server=WC_Portlet
export server1=WC_Portal
export DOMAIN_NAME='wcp-domain'
export WAIT_FOR_ADMIN_SERVER=$WAIT_FOR_ADMIN_SERVER
export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
export CONTAINERCONFIG_DIR_NAME="container-data"
export CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
export CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"
export HOST_NAME=`hostname -I`
export CONFIGURE_PORTLET=true
export port=$MANAGED_SERVER_PORT
cd /$vol_name/oracle/
MANAGED_SERVER_PORT=$MANAGED_SERVER_PORTLET_PORT
sh /$vol_name/oracle/container-scripts/startManagedServer.sh $server
if [ -e $CONTAINERCONFIG_DIR/WCPortal.PORTLET.PORTLETCONNECTION.suc ]
then
  CONFIGURE_PORTLET="false"
fi
MANAGED_SERVER_PORT=$port
if [ "$CONFIGURE_PORTLET" == "true" ]
then
  echo "Portlet Server connection is not configured."
  echo "Configuring Portlet Connection"
  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/createPortletConnection.py $HOST_NAME
  touch $CONTAINERCONFIG_DIR/WCPortal.PORTLET.PORTLETCONNECTION.suc
  echo  "Portlet Connection Configured Successfully"
  rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server1/tmp/$server1.lok
  rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/$server1.out

fi

echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $hostname $server
fi