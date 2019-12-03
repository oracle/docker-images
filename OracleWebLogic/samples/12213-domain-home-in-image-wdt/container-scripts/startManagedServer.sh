#!/bin/bash
#
#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start a Domain Managed Server.

PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/security.properties
if [ ! -e "$PROPERTIES_FILE" ]; then
    echo "A security.properties file with variable definitions needs to be supplied."
    exit
fi

JAVA_OPTIONS_PROP=`grep '^JAVA_OPTIONS=' $PROPERTIES_FILE | cut -d "=" -f2-`
if [ -z "$JAVA_OPTIONS_PROP" ]; then
    JAVA_OPTIONS_PROP="-Dweblogic.StdoutDebugEnabled=false"
fi
# Use the Env JAVA_OPTIONS if it's been set
if [ -z "$JAVA_OPTIONS" ]; then
  export JAVA_OPTIONS=${JAVA_OPTIONS_PROP}
else
  JAVA_OPTIONS="${JAVA_OPTIONS} ${JAVA_OPTIONS_PROP}"
fi

export MS_HOME="${DOMAIN_HOME}/servers/${MANAGED_SERVER_NAME}"
export MS_SECURITY="${MS_HOME}/security"
export MS_LOGS="${MS_HOME}/logs"

if [ -f ${MS_LOGS}/${MANAGED_SERVER_NAME}.log ]; then
    exit
fi

# Wait for the domain Admin Server to become available
${SCRIPT_HOME}/waitForAdminServer.sh

echo "Managed Server Name: ${MANAGED_SERVER_NAME}"
echo "Managed Server Home: ${MS_HOME}"
echo "Managed Server Security: ${MS_SECURITY}"
echo "Managed Server Logs: ${MS_LOGS}"

USER=`awk '{print $1}' $PROPERTIES_FILE | grep ^username= | cut -d "=" -f2`
if [ -z "$USER" ]; then
    echo "The admin username is blank.  The admin username must be set in the properties file."
    exit 
fi

PASS=`awk '{print $1}' $PROPERTIES_FILE | grep ^password= | cut -d "=" -f2`
if [ -z "$PASS" ]; then
    echo "The admin password is blank.  The admin password must be set in the properties file."
    exit
fi

mkdir -p ${MS_SECURITY}
echo username=$USER > ${MS_SECURITY}/boot.properties
echo password=$PASS >> ${MS_SECURITY}/boot.properties

# Start Managed Server 
${DOMAIN_HOME}/bin/setDomainEnv.sh
ADMIN_SERVER_URL="http://${ADMIN_HOST}:${ADMIN_SERVER_PORT}"
if [ "${SSL_ENABLED}" = "true" ]; then
  ADMIN_SERVER_URL="https://${ADMIN_HOST}:${ADMIN_SERVER_SSL_PORT}" 
fi
echo 'Start Managed Server: ${MANAGED_SERVER_NAME}'
${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${MANAGED_SERVER_NAME} ${ADMIN_SERVER_URL}

# Tail Managed Server Log
tail -f ${MS_LOGS}/${MANAGED_SERVER_NAME}.log &

childPID=$!
wait $childPID
