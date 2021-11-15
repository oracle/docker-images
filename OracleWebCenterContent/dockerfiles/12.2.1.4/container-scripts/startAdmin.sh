#!/bin/sh
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
#
#*************************************************************************
# script is used to start a WebLogic Admin server.
#*************************************************************************

export vol_name=u01

# Start Admin server
cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin

echo ""
echo "tail /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/weblogic.out in a new window"
./startWebLogic.sh > weblogic.out 2>&1 &

echo "waiting for server to start"

counter=0
while true; do
    grep "RUNNING" /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/weblogic.out
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

echo "AdminServer log file : /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/logs/AdminServer.log"

echo ""
echo ""
echo "Admin server running, ready to start managed server"
