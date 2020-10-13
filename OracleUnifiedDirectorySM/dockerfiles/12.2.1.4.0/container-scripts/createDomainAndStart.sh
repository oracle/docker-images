#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#

#Define DOMAIN_HOME
export DOMAIN_ROOT=${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}
export DOMAIN_HOME=${DOMAIN_ROOT}/${DOMAIN_NAME:-base_domain}
export ADMIN_NAME=AdminServer
export WLS_PLUGIN_ENABLED=${WLS_PLUGIN_ENABLED:-false}

echo "Domain Home is: " $DOMAIN_HOME

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

# Check that the User has passed on all the details needed to configure this image
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME for creating the new Domain"}"
echo "DOMAIN_HOME=$DOMAIN_HOME"

# Create an Infrastructure domain
# set environments needed for the script to work
ADD_DOMAIN=1

if [ ! -f ${DOMAIN_HOME}/servers/${ADMIN_NAME}/logs/${ADMIN_NAME}.log ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ];
then
   echo "Domain Configuration Phase"
   echo "=========================="

   echo "createOUDSMDomain(domainLocation='${DOMAIN_HOME}',weblogicPort=${ADMIN_PORT},weblogicSSLPort=${ADMIN_SSL_PORT},weblogicUserName='${ADMIN_USER}',weblogicUserPassword='${ADMIN_PASS}')" > ${ORACLE_HOME}/createOUDSMDomain.py
   if [ "${WLS_PLUGIN_ENABLED}" = "true" ]
   then
     echo "setTopologyProfile('Compact')" >> ${ORACLE_HOME}/createOUDSMDomain.py
     echo "readDomain('${DOMAIN_HOME}')" >> ${ORACLE_HOME}/createOUDSMDomain.py
     echo "cd('/Servers/AdminServer')" >> ${ORACLE_HOME}/createOUDSMDomain.py
     echo "cmo.setWeblogicPluginEnabled(true)" >> ${ORACLE_HOME}/createOUDSMDomain.py
     echo "updateDomain()" >> ${ORACLE_HOME}/createOUDSMDomain.py
     echo "closeDomain()" >> ${ORACLE_HOME}/createOUDSMDomain.py
     echo "exit()" >> ${ORACLE_HOME}/createOUDSMDomain.py
   fi
   wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/createOUDSMDomain.py
   retval=$?

   echo  "RetVal from Domain creation $retval"

   if [ $retval -ne 0 ];
   then
       echo "Domain Creation Failed.. Please check the Domain Logs"
       exit
   fi

   rm ${ORACLE_HOME}/createOUDSMDomain.py

   # Create the security file to start the server(s) without the password prompt
   mkdir -p ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/
   echo "username=${ADMIN_USER}" >> ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/boot.properties
   echo "password=${ADMIN_PASS}" >> ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/boot.properties

   ${DOMAIN_HOME}/bin/setDomainEnv.sh
fi

#Set Java options
export JAVA_OPTIONS=${JAVA_OPTIONS}
echo "Java Options: ${JAVA_OPTIONS}"

echo "Starting the Admin Server"
echo "=========================="

# Start Admin Server and tail the logs
${DOMAIN_HOME}/startWebLogic.sh &
sleep 60s
touch ${DOMAIN_HOME}/servers/${ADMIN_NAME}/logs/${ADMIN_NAME}.log
tail -f ${DOMAIN_HOME}/servers/${ADMIN_NAME}/logs/${ADMIN_NAME}.log &

childPID=$!
wait $childPID
