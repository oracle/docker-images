#!/bin/bash
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This script is used to stop a WebLogic Admin server.
#
export DOMAIN_NAME=$DOMAIN_NAME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"

. $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

# Stop Admin server
cd $DOMAIN_HOME/bin
if grep -q "RUNNING" $DOMAIN_HOME/bin/weblogic.out
then
    ./stopWebLogic.sh
    rm -f $DOMAIN_HOME/bin/weblogic.out
fi
sleep 5
rm -f $DOMAIN_HOME/servers/AdminServer/tmp/AdminServer.lok

echo "Admin Server stopped successfully."
