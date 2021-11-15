#!/bin/sh
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
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

# removing proxy settings if any
unset http_proxy
unset https_proxy

#Loop determining state of WLS
function check_wls {
    
    SERVER=$1
    echo ""
    echo "tail $WCC_START_LOGFILE in a new window"
	
    echo "Starting $SERVER..."
    
counter=0
while true; do
    grep "Server state changed to RUNNING" $WCC_START_LOGFILE
    status=$?
    if [ $status -eq 0 ]; then
        echo "$SERVER started [OK]"
        break;
    elif [[ "$counter" -gt 25 ]]; then
        echo "$SERVER timed out, exiting"
        exit $status
    else
        counter=$((counter+1))
        echo "Waiting for $SERVER to start ."
        sleep 10
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
echo "===================================="
echo "Starting Managed Server : $server"
echo "===================================="
echo ""

echo "HOSTNAME=${hostname}"

WCC_START_LOGFILE="${CONTAINERCONFIG_LOG_DIR}/${server}_start-$(sed 's/-.*//' <<< $hostname).log"
rm -rf $WCC_START_LOGFILE
echo "Saving the server creation log to: ${WCC_START_LOGFILE}"

cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
echo ""
echo ""

./startManagedWebLogic.sh $server "http://"$adminhostname:$adminport > $WCC_START_LOGFILE 2>&1 &

echo ""
echo ""

check_wls $server

echo ""
echo ""

echo "$server log file :  /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/logs/$server.log"

echo ""
echo ""
echo "$server server has been started."
echo ""
echo ""

cd /$vol_name/oracle
