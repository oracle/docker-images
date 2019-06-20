#!/bin/bash
#
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#Define CUSTOM_DOMAIN_HOME
export DOMAIN_HOME=$CUSTOM_DOMAIN_ROOT/$CUSTOM_DOMAIN_NAME
echo "Domain Home is:  $DOMAIN_HOME"
echo "Domain Root is:  $CUSTOM_DOMAIN_ROOT"

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

echo "Configuring Domain for first time "
echo "Start the Admin and Managed Servers  "
echo "====================================="

# Check that the User has passed on all the details needed to configure this image
# Settings to call RCU....
echo "CUSTOM_CONNECTION_STRING=${CUSTOM_CONNECTION_STRING:?"Please set CONNECTION_STRING for connecting to the Database"}"
echo "CUSTOM_RCUPREFIX=${CUSTOM_RCUPREFIX:?"Please set RCUPREFIX for the database schemas"}"
echo "CUSTOM_DOMAIN_NAME=${CUSTOM_DOMAIN_NAME:?"Please set DOMAIN_NAME for creating the new Domain"}"
echo "DOMAIN_HOME=$DOMAIN_HOME"

CONTAINERCONFIG_DIR=/u01/oracle/ContainerData

export jdbc_url="jdbc:oracle:thin:@"$CUSTOM_CONNECTION_STRING

echo "CONNECTION_STRING=$CUSTOM_CONNECTION_STRING"
echo "RCUPREFIX=$CUSTOM_RCUPREFIX"
echo "jdbc_url=$jdbc_url"


# Create an Infrastructure domain
# set environments needed for the script to work
ADD_DOMAIN=1

if [ ! -f ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ];
then
   echo "Creating Domain 1st execution"
   # mkdir -p $ORACLE_HOME/properties
   # Create Domain only if 1st execution
   echo ls -l /u01/oracle/properties
   SEC_PROPERTIES_FILE=/u01/oracle/properties/domain_security.properties
   if [ ! -e "$SEC_PROPERTIES_FILE" ]; then
      echo "A properties file with the username and password needs to be supplied."
      exit
   fi

   # Get Username
   USER=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep username | cut -d "=" -f2`
   if [ -z "$USER" ]; then
      echo "The domain username is blank.  The Admin username must be set in the properties file."
      exit
   fi
   # echo "Username: $USER"
   # Get Password
   PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep password | cut -d "=" -f2`
   if [ -z "$PASS" ]; then
      echo "The domain password is blank.  The Admin password must be set in the properties file."
      exit
   fi
   # echo "Password: $PASS"
   # echo "Database Password $DB_PASS"
   SEC_RCU_PROPERTIES_FILE=/u01/oracle/properties/rcu_security.properties
   if [ ! -e "$SEC_RCU_PROPERTIES_FILE" ]; then
      echo "A properties file with the database schema password needs to be supplied."
      exit
   fi
   # Get databasse Schema Password
   DB_SCHEMA_PASS=`awk '{print $1}' $SEC_RCU_PROPERTIES_FILE | grep db_schema | cut -d "=" -f2`
   if [ -z "$DB_SCHEMA_PASS" ]; then
      echo "The databse schema password is blank.  The database schema password must be set in the properties file."
      exit
   fi
   # echo "Database Schema Password: $DB_SCHEMA_PASS"

   echo "Domain Configuration Phase"
   echo "=========================="
   wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/createFMWDomain.py -oh ${ORACLE_HOME} -jh ${JAVA_HOME} -parent ${CUSTOM_DOMAIN_ROOT} -name ${CUSTOM_DOMAIN_NAME} -user ${USER} -password ${PASS} -rcuDb ${CUSTOM_CONNECTION_STRING} -rcuPrefix ${CUSTOM_RCUPREFIX} -rcuSchemaPwd ${DB_SCHEMA_PASS} -adminListenPort ${CUSTOM_ADMIN_LISTEN_PORT} -adminName ${CUSTOM_ADMIN_NAME} -managedNameBase ${CUSTOM_MANAGED_BASE_NAME} -managedServerPort ${CUSTOM_MANAGEDSERVER_PORT} -prodMode ${CUSTOM_PRODUCTION_MODE} -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} -clusterName ${CUSTOM_CLUSTER_NAME}
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

fi

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
