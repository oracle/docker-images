#!/bin/bash
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This script is used to start a WebLogic Admin server. And tail the logs.
#

export DOMAIN_NAME=$DOMAIN_NAME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"

. $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

# Start Admin server
cd $DOMAIN_HOME/bin

echo ""
echo "tail $DOMAIN_HOME/bin/weblogic.out in a new window"
./startWebLogic.sh > weblogic.out 2>&1 &

echo "waiting for server to start"

counter=0
while true; do
    grep "RUNNING" $DOMAIN_HOME/bin/weblogic.out
    status=$?
    if [ $status -eq 0 ]; then
        echo "Admin Server started ."
        break;
    elif [[ "$counter" -gt 25 ]]; then
        echo "Server timed out, exiting"
        exit $status
    else
        counter=$((counter+1))
        echo "Waiting for Admin Server to start ."
        sleep 10
    fi
done

echo ""
echo ""

echo "AdminServer log file : $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log"

echo ""
echo ""
echo "Admin server running, ready to start Managed server"
