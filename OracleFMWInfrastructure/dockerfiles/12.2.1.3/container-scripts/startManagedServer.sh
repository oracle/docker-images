#!/bin/bash
#
# Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# If log.nm does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer, as well Managed Server
# Otherwise, only start NM (container is being restarted)o

export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME=${DOMAIN_ROOT}/${DOMAIN_NAME}
echo "Domain Home is: " $DOMAIN_HOME

export MS_HOME="${DOMAIN_HOME}/servers/${MANAGED_NAME}"
export MS_SECURITY="${MS_HOME}/security"

# Wait for AdminServer to become available for any subsequent operation
/u01/oracle/container-scripts/waitForAdminServer.sh

echo "Managed Server Name: ${MANAGED_NAME}"
echo "Managed Server Home: ${MS_HOME}"
echo "Managed Server Security: ${MS_SECURITY}"

#  Create Domain only if 1st execution
SEC_PROPERTIES_FILE=/u01/oracle/properties/domain_security.properties
if [ ! -e "$SEC_PROPERTIES_FILE" ]; then
    echo "A properties file with the username and password needs to be supplied."
    exit
fi

if [ ! -f "${MS_SECURITY}/boot.properties" ]; then
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

  #Set Java options
  #JAVA_OPTIONS="-Dweblogic.StdoutDebugEnabled=false"
  #export JAVA_OPTIONS=${JAVA_OPTIONS}
  #echo "Java Options: ${JAVA_OPTIONS}"

  # Create Managed Server
  mkdir -p ${MS_SECURITY}
  chmod +w ${MS_SECURITY}
  echo "Make directory ${MS_SECURITY} to create boot.properties"
  echo "username=${USER}" >> ${MS_SECURITY}/boot.properties
  echo "password=${PASS}" >> ${MS_SECURITY}/boot.properties
fi

${DOMAIN_HOME}/bin/setDomainEnv.sh

# Start 'ManagedServer'
echo "Start Managed Server"
if [ ${ADMINISTRATION_PORT_ENABLED} == "true" ]
then
   JAVA_OPTIONS="-Dweblogic.security.SSL.ignoreHostnameVerification=true"
   echo "Connecting to Admin Server at https://${ADMIN_HOST}:${ADMINISTRATION_PORT}"
   ${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${MANAGED_NAME} "https://${ADMIN_HOST}:${ADMINISTRATION_PORT}"
else
   echo "Connecting to Admin Server at http://${ADMIN_HOST}:${ADMIN_LISTEN_PORT}"
   ${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${MANAGED_NAME} "http://${ADMIN_HOST}:${ADMIN_LISTEN_PORT}"
fi 

# tail Managed Server log
tail -f ${MS_HOME}/logs/${MANAGED_NAME}.log &

childPID=$!
wait $childPID
