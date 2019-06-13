#!/bin/bash
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

export DOMAIN_HOME=$CUSTOM_DOMAIN_ROOT/$CUSTOM_DOMAIN_NAME
echo "Domain Home is:  $DOMAIN_HOME"

export MS_HOME="${DOMAIN_HOME}/servers/${CUSTOM_MANAGED_NAME}"
export MS_SECURITY="${MS_HOME}/security"

# Wait for AdminServer to become available for any subsequent operation
/u01/oracle/container-scripts/waitForAdminServer.sh

echo "Managed Server Name: ${CUSTOM_MANAGED_NAME}"
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

  # Get Password
  PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep password | cut -d "=" -f2`
  if [ -z "$PASS" ]; then
     echo "The domain password is blank.  The Admin password must be set in the properties file."
     exit
  fi

  # Create Managed Server
  mkdir -p ${MS_SECURITY}
  chmod +w ${MS_SECURITY}
  echo "Make directory ${MS_SECURITY} to create boot.properties"
  echo "username=${USER}" >> ${MS_SECURITY}/boot.properties
  echo "password=${PASS}" >> ${MS_SECURITY}/boot.properties
fi


#Set Java options
#JAVA_OPTIONS="-Dweblogic.StdoutDebugEnabled=false"
export JAVA_OPTIONS=${CUSTOM_JAVA_OPTIONS}
echo "Java Options: ${JAVA_OPTIONS}"

${DOMAIN_HOME}/bin/setDomainEnv.sh

echo "Connecting to Admin Server at http://${CUSTOM_ADMIN_HOST}:${CUSTOM_ADMIN_PORT}"
${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${CUSTOM_MANAGED_NAME} "http://${CUSTOM_ADMIN_HOST}:${CUSTOM_ADMIN_PORT}"

# tail Managed Server log
tail -f ${MS_HOME}/logs/${CUSTOM_MANAGED_NAME}.log &

childPID=$!
wait $childPID
