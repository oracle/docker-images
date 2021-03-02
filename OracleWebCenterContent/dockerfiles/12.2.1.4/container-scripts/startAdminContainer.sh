#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

echo ""
echo "Starting Node Manager"
echo "====================="
echo ""
echo "tail /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/nodemanager.out in a new window"
echo ""

export HOSTNAME=$HOSTNAME
echo "HOSTNAME=${HOSTNAME}"

CONFIGURE_DOMAIN="true"
echo "CONFIGURE_DOMAIN=${CONFIGURE_DOMAIN}"

cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
./startNodeManager.sh > nodemanager.out 2>&1&
sleep 10

# Now we start the Admin server in this container...
sh /$vol_name/oracle/container-scripts/startAdmin.sh

if [ "$CONFIGURE_DOMAIN" == "true" ]
then
  echo "Assigning machines and clusters to the managed servers"
  echo "======================================================"
  echo ""
  # assign machines and clusters to managed servers
  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/setTopology.py $HOSTNAME

 # Configure Node Manager
  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/configureNodeManager.py $HOSTNAME $vol_name

  # Configure identity store
  if [ "$CONFIGURE_OID" == "true" ]
  then
    /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/configureIdentityStore.py $HOSTNAME $CONFIGURE_OID $OID_HOST $OID_PORT $OID_PWD $OID_AUTH_TYPE
  fi

  # Restart admin server
  sh /$vol_name/oracle/container-scripts/stopAdmin.sh
  sleep 10
  sh /$vol_name/oracle/container-scripts/startAdmin.sh
fi

cd /$vol_name/oracle/

echo ""
echo "now keepContainerAlive ..."
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  export ADMIN_SERVER_NAME=AdminServer
  echo "ADMIN_SERVER_NAME=${ADMIN_SERVER_NAME}"
  echo "CONTAINERCONFIG_LOG_DIR=${CONTAINERCONFIG_LOG_DIR}"
  echo "HOSTNAME=${HOSTNAME}"  
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $HOSTNAME $ADMIN_SERVER_NAME
fi

echo "END OF FILE"

