#!/bin/bash
#
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This script is used to start a Managed server.
#
export DOMAIN_NAME=$DOMAIN_NAME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"

. $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $SERVER_NAME "http://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT
   exit;
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $SERVER_NAME "http://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT
   exit;
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

if [ "$1" = "" ] ; then
        usage $0
        exit
else
        SERVER_NAME="$1"
        shift
fi

export SERVER_NAME=$SERVER_NAME

# Start Managed server

cd $DOMAIN_HOME/bin
echo ""
echo "tail $DOMAIN_HOME/bin/$SERVER_NAME.out in a new window"
./startManagedWebLogic.sh $SERVER_NAME "http://"$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT > $SERVER_NAME.out 2>&1 &
echo ""
echo ""

echo "Waiting for server to start"
while true; do
    grep "RUNNING" $DOMAIN_HOME/bin/$SERVER_NAME.out
    status=$?
    if [ $status -eq 0 ]; then
        echo "$SERVER_NAME Server started ."
        break;
    elif [[ "$counter" -gt 36 ]]; then
        echo "SERVER_NAME timed out, exiting"
        exit $status
    else
        counter=$((counter+1))
        echo "Waiting for $SERVER_NAME Server to start ......"
        sleep 20
    fi
done

echo ""
echo ""

echo "$SERVER_NAME log file :  $DOMAIN_HOME/servers/$SERVER_NAME/logs/$SERVER_NAME.log"

echo ""
echo ""
echo "$SERVER_NAME server has been started."
