#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
export vol_name=u01
export server=WC_Portal
export $DOMAIN_NAME='wcp-domain'

########### SIGINT handler ############
function _int() {
   echo "Stopping container.."
   echo "SIGINT received, shutting down servers!"
   echo ""
   echo "Stopping Managed Server.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopManagedWebLogic.sh $server
   rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/tmp/$server.lok
   exit;
EOF
   lsnrctl stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container.."
   echo "SIGTERM received, shutting down Servers!"
   echo ""
   echo "Stopping Managed Server.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopManagedWebLogic.sh $server
   rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/tmp/$server.lok
   exit;
EOF
   lsnrctl stop
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down Servers!"
   echo ""
   echo "Stopping Managed Server.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopManagedWebLogic.sh $server
   rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/tmp/$server.lok
   exit;
EOF
   lsnrctl stop
}

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

if [ -z ${WAIT_FOR_ADMIN_SERVER} ]
then
    # by default we always keep this flag OFF
    export WAIT_FOR_ADMIN_SERVER="false"
fi

if [ -z ${KEEP_CONTAINER_ALIVE} ]
then
   # by default we always keep this flag ON
   export KEEP_CONTAINER_ALIVE="true"
fi

export WAIT_FOR_ADMIN_SERVER=$WAIT_FOR_ADMIN_SERVER
export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
export CONTAINERCONFIG_DIR_NAME="container-data"
export CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
export CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"
export hostname=`hostname -I`
CONFIGURE_UCM="true"

# start WC_Portal server in the container
echo ""
echo "========================================================="
echo "            WebCenter Portal Docker Container            "
echo "                      Portal Server                      "
echo "                       12.2.1.4.0                        "
echo "========================================================="
echo ""
echo ""

cd /$vol_name/oracle/
sh /$vol_name/oracle/container-scripts/startManagedServer.sh $server

if [ -e $CONTAINERCONFIG_DIR/WCPortal.UCM.$UCM_CONNECTION_NAME.suc ]
then
  CONFIGURE_UCM="false"
fi

if [ "$CONFIGURE_UCM" == "true" ]
then
  echo "Content Server connection is not configured."
  if [ "$CONFIGURE_UCM_CONNECTION" == "true" ]
  then
    echo "Creating content Server connection."
    #create Content Server Connection
    sh /$vol_name/oracle/container-scripts/createContentServerConnection.sh

    # Write the ucm suc file... 
    touch $CONTAINERCONFIG_DIR/WCPortal.UCM.$UCM_CONNECTION_NAME.suc
  else
    echo "Content Server configure is not selected in configure map, CONFIGURE_UCM_CONNECTION = $CONFIGURE_UCM_CONNECTION ."
  fi
fi

echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $hostname $server
fi

