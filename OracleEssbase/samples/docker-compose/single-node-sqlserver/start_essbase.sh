#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

DIR=`cd -P $(dirname $0);pwd`

# default values
export ADMIN_SERVER_PORT=${ADMIN_SERVER_PORT:-7001}
export ADMIN_SERVER_SSL_PORT=${ADMIN_SERVER_SSL_PORT:-7002}
export MANAGED_SERVER_PORT=${MANAGED_SERVER_PORT:-9000}
export MANAGED_SERVER_SSL_PORT=${MANAGED_SERVER_SSL_PORT:-9001}
export SECURE_MODE=${SECURE_MODE:-false}

STACK_INSTANCE_NAME=${STACK_INSTANCE_NAME:-sample}
STACK_INSTANCE_NAME=${STACK_INSTANCE_NAME,,}

echo "Starting Essbase stack - ${STACK_INSTANCE_NAME}"

docker-compose --project-name ${STACK_INSTANCE_NAME} up \
               --detach --force-recreate

cleanupOnFailure() {
   rv="$?"
   if [ "$rv" -ne 0 ]; then
      echo "Cleaning up environment due to failure"
      docker-compose --project-name $1 down --volumes
   fi
   exit $rv
}

trap "cleanupOnFailure ${STACK_INSTANCE_NAME}" EXIT

# Wait for server to come up
echo Waiting for Essbase service to be available
sleep 300
readyUrl="http://localhost:$MANAGED_SERVER_PORT/weblogic/ready"
essbaseUrl="http://localhost:$MANAGED_SERVER_PORT/essbase"
if [ "${SECURE_MODE}" == "true" ]; then
   readyUrl="https://localhost:$MANAGED_SERVER_SSL_PORT/weblogic/ready"
   essbaseUrl="https://localhost:$MANAGED_SERVER_SSL_PORT/essbase"
fi

echo Pinging $readyUrl
until $(curl --output /dev/null --insecure --silent --head --fail $readyUrl); do
   sleep 5
   echo Pinging $readyUrl
done

echo "Essbase service is ready at $essbaseUrl"
