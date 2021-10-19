#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
export vol_name=u01
export server=WC_Portlet
export DOMAIN_NAME='wcp-domain'

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

 #start WC_Portlet server in the container
echo ""
echo "========================================================="
echo "            WebCenter Portlet Docker Container            "
echo "                      Portlet Server                      "
echo "                       12.2.1.4                        "
echo "========================================================="
echo ""
echo ""

sh /$vol_name/oracle/container-scripts/installPortletAndStart.sh



