#!/bin/bash
#
#Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start the domain Admin Server.

# Locate the runtime properties
PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/security.properties
if [ ! -e "$PROPERTIES_FILE" ]; then
    echo "A security.properties file with the username and password needs to be supplied."
    exit
fi

# Define Admin Server JAVA_OPTIONS
JAVA_OPTIONS=`awk '{print $1}' $PROPERTIES_FILE | grep ^JAVA_OPTIONS= | cut -d "=" -f2`
if [ -z "${JAVA_OPTIONS}" ]; then
    JAVA_OPTIONS="-Dweblogic.StdoutDebugEnabled=false"
fi
export ${JAVA_OPTIONS}
echo "Java Options: ${JAVA_OPTIONS}"

# Define start of Derby Database
CUSTOM_DERBY_FLAG=`awk '{print $1}' $PROPERTIES_FILE | grep ^DERBY_FLAG= | cut -d "=" -f2`
if [ -n "${CUSTOM_DERBY_FLAG}" ]; then
    DERBY_FLAG="${CUSTOM_DERBY_FLAG}"
fi
 
export ${DERBY_FLAG}
echo "Start Derby: ${DERBY_FLAG}"

export AS_HOME="${DOMAIN_HOME}/servers/${ADMIN_NAME}"
export AS_SECURITY="${AS_HOME}/security"
export AS_LOGS="${AS_HOME}/logs"

if [ -f ${AS_LOGS}}/${ADMIN_NAME}.log ]; then
    exit
fi

echo "Admin Server Home: ${AS_HOME}"
echo "Admin Server Security: ${AS_SECURITY}"
echo "Admin Server Logs: ${AS_LOGS}"

USER=`awk '{print $1}' $PROPERTIES_FILE | grep ^username= | cut -d "=" -f2`
if [ -z "$USER" ]; then
    echo "The domain username is blank.  The Admin username must be set in the properties file."
    exit 1
fi

PASS=`awk '{print $1}' $PROPERTIES_FILE | grep ^password= | cut -d "=" -f2`
if [ -z "$PASS" ]; then
    echo "The domain password is blank.  The Admin password must be set in the properties file."
    exit 1
fi

mkdir -p ${AS_SECURITY}
echo "username=${USER}" >> ${AS_SECURITY}/boot.properties
echo "password=${PASS}" >> ${AS_SECURITY}/boot.properties

# Start Admin Server and tail the logs
${DOMAIN_HOME}/bin/setDomainEnv.sh
${DOMAIN_HOME}/startWebLogic.sh

tail -f ${AS_LOGS}/${ADMIN_NAME}.log &

childPID=$!
wait $childPID
