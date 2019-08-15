#!/bin/bash
#
#Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


# If AdminServer.log does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer
# Otherwise, only start NM (container restarted)
########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the server!"
   ${DOMAIN_HOME}/bin/stopWebLogic.sh
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

export DOMAIN_HOME=$CUSTOM_DOMAIN_ROOT/$CUSTOM_DOMAIN_NAME
echo "Domain Home is:  $DOMAIN_HOME"

if [  -f ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log ]; then
    exit
fi

SEC_PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/domain_security.properties
echo $SEC_PROPERTIES_FILE
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

DOMAIN_PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/domain.properties
echo $DOMAIN_PROPERTIES_FILE
if [ ! -e "${DOMAIN_PROPERTIES_FILE}" ]; then
   echo "A Domain properties file needs to be supplied."
   exit
fi

# Create domain
wlst.sh -skipWLSModuleScanning -loadProperties ${DOMAIN_PROPERTIES_FILE} -loadProperties ${SEC_PROPERTIES_FILE}  /u01/oracle/container-scripts/create-wls-domain.py
retval=$?

echo  "RetVal from Domain creation $retval"

if [ $retval -ne 0 ];
then
   echo "Domain Creation Failed.. Please check the Domain Logs"
   exit
fi

# Create the security file to start the server(s) without the password prompt
mkdir -p ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/
echo "username=${USER}" >> ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/boot.properties
echo "password=${PASS}" >> ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/boot.properties

#Set Java options
export JAVA_OPTIONS=${CUSTOM_JAVA_OPTIONS}
echo "Java Options: ${JAVA_OPTIONS}"

${DOMAIN_HOME}/bin/setDomainEnv.sh

echo "Starting the Admin Server"
echo "=========================="

# Start Admin Server and tail the logs
${DOMAIN_HOME}/startWebLogic.sh
touch ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log
tail -f ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log &

childPID=$!
wait $childPID

