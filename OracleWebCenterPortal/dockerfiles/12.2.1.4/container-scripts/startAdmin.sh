#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#*************************************************************************
# script is used to start a WebLogic Admin server.
#*************************************************************************
#
export vol_name=u01
export hostname=`hostname -I`

#Loop determining state of WLS
function check_wls {
    SERVER=$1
    action=$2
    host=$3
    admin_port=$4
    echo "Starting $SERVER..."
    started_url="http://$host:$admin_port/weblogic/ready"
    echo "Checking for server to be available -> $started_url ..."
    counter=0
    while true
    do
        sleep 10
        counter=$((counter + 1))
        if [ "$action" == "started" ]; then
          echo "waiting for server $SERVER..."
          status=`/usr/bin/curl -s -i $started_url | grep "200 OK"`
          if [ ! -z "$status" ]; then
            echo "$SERVER has $action [OK]"
            break
          fi
        elif [[ "$counter" -gt 25 ]]; then
          echo "Server timed out, exiting..."
          exit $status
        fi
    done
    echo ""
    echo ""
}
 
# Start Admin server
echo ""
echo ""
echo "====================="
echo "Starting Admin Server"
echo "====================="
echo ""
echo ""

# removing any proxy settings
unset http_proxy
unset https_proxy

ADMIN_START_LOGFILE="${CONTAINERCONFIG_LOG_DIR}/AdminServer_start-$(sed 's/-.*//' <<< $hostname).log"
rm -f $ADMIN_START_LOGFILE
echo "Saving the server creation log to: ${ADMIN_START_LOGFILE}"

cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
./startWebLogic.sh > ${ADMIN_START_LOGFILE} 2>&1 &
echo ""
echo ""

check_wls "Admin Server" "started" $hostname $ADMIN_PORT

echo ""
echo ""
echo "AdminServer log file : /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/logs/AdminServer.log"
echo ""
echo ""
echo "Admin server running, ready to start Managed server."
echo ""
echo ""

cd /$vol_name/oracle/


