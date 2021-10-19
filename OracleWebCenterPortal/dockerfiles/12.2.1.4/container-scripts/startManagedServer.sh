#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
usage()
{
  echo "Need to specify SERVER_NAME in command line:"
  echo "Usage: $1 SERVER_NAME "
  echo "for example:"
  echo "$1 managedserver1"
}

#  Set SERVER_NAME to the name of the server you wish to start up.

if [ "$1" = "" ] ; then
        usage $0
        exit
else
        server="$1"
        shift
fi

export vol_name=u01
export adminhostname=$ADMIN_SERVER_CONTAINER_NAME
export adminport=$ADMIN_PORT
export server=$server 
export DOMAIN_NAME='wcp-domain'

# removing proxy settings if any
unset http_proxy
unset https_proxy

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

#
# Make sure the Admin Server is up and running
#
if [ "$WAIT_FOR_ADMIN_SERVER" == "true" ]
then
  echo ""
  echo "Waiting for WebLogic Admin Server on $adminhostname:$adminport to become available..."
  while :
  do
    (echo > /dev/tcp/$adminhostname/$adminport) >/dev/null 2>&1
    available=$?
    if [[ $available -eq 0 ]]; then
      echo "WebLogic Admin Server is now available. Proceeding..."
      break
    fi
    sleep 5
  done
fi

# Start Managed server
echo ""
echo ""
echo "===================================="
echo "Starting Managed Server : $server"
echo "===================================="
echo ""
echo ""

WCP_START_LOGFILE="${CONTAINERCONFIG_LOG_DIR}/${server}_start-$(sed 's/-.*//' <<< $hostname).log"
rm -rf $WCP_START_LOGFILE
echo "Saving the server creation log to: ${WCP_START_LOGFILE}"

cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
echo ""
echo ""

./startManagedWebLogic.sh $server "http://"$adminhostname:$adminport > $WCP_START_LOGFILE 2>&1 &

echo ""
echo ""

check_wls $server "started" $hostname $MANAGED_SERVER_PORT

echo ""
echo ""

echo "$server log file :  /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/logs/$server.log"

echo ""
echo ""
echo "$server server has been started."
echo ""
echo ""

cd /$vol_name/oracle

