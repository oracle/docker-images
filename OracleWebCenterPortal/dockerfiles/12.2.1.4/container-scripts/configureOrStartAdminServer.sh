#!/bin/bash
# Copyright (c)  2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
export vol_name=u01
export $DOMAIN_NAME='wcp-domain'

########### SIGINT handler ############
function _int() {
   echo "Stopping container.."
   echo "SIGINT received, shutting down servers!"
   echo ""
   echo "Stopping Node Manager.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopNodeManager.sh
   echo "Stopping Admin Server.."
   /$vol_name/oracle/container-scripts/stopAdmin.sh
   exit;
EOF
   lsnrctl stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container.."
   echo "SIGTERM received, shutting down Servers!"
   echo ""
   echo "Stopping Node Manager.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopNodeManager.sh
   echo "Stopping Admin Server.."
   /$vol_name/oracle/container-scripts/stopAdmin.sh
   exit;
EOF
   lsnrctl stop
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down Servers!"
   echo ""
   echo "Stopping Node Manager.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopNodeManager.sh
   echo "Stopping Admin Server.."
   /$vol_name/oracle/container-scripts/stopAdmin.sh
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

export CONTAINERCONFIG_DIR_NAME="container-data"
export CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
export CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"
export CONTAINERCONFIG_DOMAIN_DIR="/$vol_name/oracle/user_projects/domains"

echo ""
echo "========================================================="
echo "            WebCenter Portal Docker Container            "
echo "                      Admin Server                       "
echo "                       12.2.1.4.0                        "
echo "========================================================="
echo ""
echo ""


# configuring or starting admin server as oracle user
sh /$vol_name/oracle/container-scripts/createWCPInfraAndStartAdmin.sh

