#!/bin/bash
#
# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
# If log.nm does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer, as well Managed Server
# Otherwise, only start NM (container is being restarted)o
RUNTIME_PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/domain.properties

ADMIN_HOST=`awk '{print $1}' ${RUNTIME_PROPERTIES_FILE} | grep ^ADMIN_HOST= | cut -d "=" -f2`
if [ -z "${ADMIN_SERVER_NAME}" ]; then
   ADMIN_HOST="wlsadmin"
fi
echo "Admin Server Host: ${ADMIN_HOST}"
export ADMIN_HOST=${ADMIN_HOST}

JAVA_OPTIONS=`awk '{print $1}' ${RUNTIME_PROPERTIES_FILE} | grep ^JAVA_OPTIONS= | cut -d "=" -f2`
if [ -z "${JAVA_OPTIONS}" ]; then 
   JAVA_OPTIONS="-Dweblogic.StdoutDebugEnabled=false"
fi
export JAVA_OPTIONS=${JAVA_OPTIONS}
echo "Java Options: ${JAVA_OPTIONS}"

export MS_HOME="${DOMAIN_HOME}/servers/${MANAGE_S_NAME}"
export MS_SECURITY="${MS_HOME}/security"

if [ -f ${MS_HOME}/logs/${MANAGE_S_NAME}.log ]; then
   exit
fi

# Wait for AdminServer to become available for any subsequent operation
/u01/oracle/waitForAdminServer.sh

echo "Managed Server Name: ${MANAGE_S_NAME}"
echo "Managed Server Home: ${MS_HOME}"
echo "Managed Server Security: ${MS_SECURITY}"

SEC_PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/security.properties
if [ ! -e "${SEC_PROPERTIES_FILE}" ]; then
   echo "A properties file with the username and password needs to be supplied."
   exit
fi
# Get Username
USER=`awk '{print $1}' ${SEC_PROPERTIES_FILE} | grep username | cut -d "=" -f2`
if [ -z "${USER}" ]; then
   echo "The domain username is blank.  The Admin username must be set in the properties file."
   exit
fi
# Get Password
PASS=`awk '{print $1}' ${SEC_PROPERTIES_FILE} | grep password | cut -d "=" -f2`
if [ -z "${PASS}" ]; then
   echo "The domain password is blank.  The Admin password must be set in the properties file."
   exit
fi

# Create Managed Server
mkdir -p ${MS_SECURITY}
echo "username=${USER}" >> ${MS_SECURITY}/boot.properties
echo "password=${PASS}" >> ${MS_SECURITY}/boot.properties
${DOMAIN_HOME}/bin/setDomainEnv.sh

# Start 'ManagedServer'
echo "Start Managed Server"
${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${MANAGE_S_NAME} http://${ADMIN_HOST}:${ADMIN_PORT}

# tail Managed Server log
tail -f ${MS_HOME}/logs/${MANAGE_S_NAME}.log &

childPID=$!
wait $childPID
