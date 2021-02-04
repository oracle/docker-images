#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions
checkNonRoot $(basename $0)

printVersionInfo
log "Starting Oracle Essbase managed server ${SERVER_NAME}..."

# Update local healthcheck script
sed -i "s|SERVER_NAME=.*|SERVER_NAME=${SERVER_NAME}|g" /u01/container-scripts/healthcheck.sh

# Process the configuration parameters
processParameters
mandatoryParameters="ORACLE_HOME DOMAIN_HOME ARBORPATH ADMIN_USERNAME ADMIN_PASSWORD SERVER_NAME "
if (( $DATABASE_WAIT_TIMEOUT > 0 )); then
  mandatoryParameters="${mandatoryParameters} DATABASE_TYPE DATABASE_CONNECT_STRING"
  if [ -z "${DATABASE_SCHEMA_PASSWORD}" ]; then
    mandatoryParameters="${mandatoryParameters} DATABASE_ADMIN_USERNAME DATABASE_ADMIN_PASSWORD"
  else
    mandatoryParameters="${mandatoryParameters} DATABASE_SCHEMA_PASSWORD DATABASE_SCHEMA_PREFIX" 
  fi
fi
checkMandatoryParameters ${mandatoryParameters}

# Ping database
if (( $DATABASE_WAIT_TIMEOUT > 0 )); then
  if [ -z "${DATABASE_SCHEMA_PASSWORD}" ]; then
    echo $DATABASE_ADMIN_PASSWORD | ${SCRIPT_DIR}/waitForDatabase.sh "$DATABASE_ADMIN_USERNAME" "$DATABASE_ADMIN_ROLE"
    rc=$?
  else 
    echo $DATABASE_SCHEMA_PASSWORD | ${SCRIPT_DIR}/waitForDatabase.sh "${DATABASE_SCHEMA_PREFIX}_ESSBASE"
    rc=$?
  fi
  [ $rc -eq 0 ] || exit $rc
fi

# Wait for the domain to be configured, assumes /u01/config is shared
domain_marker_success_file=/u01/config/.marker.domain.success
domain_marker_failed_file=/u01/config/.marker.domain.failed
while [[ ! -e "${domain_marker_success_file}" ]] && [[ ! -e "${domain_marker_failed_file}" ]]; do
  log "Waiting for domain creation to be complete"
  sleep 5
done

if [ -e ${domain_marker_failed_file} ]; then
   rc=$(cat "${domain_marker_failed_file}")
   exit $rc
fi

# Make required directories
mkdir -p ${ARBORPATH}
mkdir -p ${TMP_DIR}
mkdir -p ${CRASHDUMP_LOCATION}

# Wait for AdminServer to become available for any subsequent operation
${SCRIPT_DIR}/waitForAdminServer.sh

# Create the security file to start the server(s) without the password prompt
log "Writing boot.properties file for ${SERVER_NAME}"
${SCRIPT_DIR}/run-wlst.sh ${SCRIPT_DIR}/wlst/write_server_boot_properties.py ${DOMAIN_HOME} ${SERVER_NAME} > /dev/null 2>&1 <<EOL
${ADMIN_USERNAME}
${ADMIN_PASSWORD}
EOL

# Signal handlers
childPid=0
_stopManagedServer() {
  log "Shutting down the container!"
  if [ ${childPid} -ne 0 ]; then
     echo ${ADMIN_PASSWORD} | ${SCRIPT_DIR}/_stopManagedServer.sh ${ADMIN_USERNAME}
     kill -9 ${childPid} 2> /dev/null
  fi
}

trap '_stopManagedServer' SIGINT SIGTERM

# Start the managed server
JAVA_OPTIONS="-XX:+PrintFlagsFinal -Dweblogic.StdoutDebugEnabled=false"

# Special handling for eas_server1
if [ "${SERVER_NAME}" == "eas_server1" ]; then
  if [ -n "${EAS_SERVER_HOSTNAME_ALIAS}" ]; then
    JAVA_OPTIONS="${JAVA_OPTIONS} -DESSBASE_HOSTNAME=${EAS_SERVER_HOSTNAME_ALIAS}"
  fi
  
  if [ -z "${DISCOVERY_URL_OVERRIDE}" ]; then
     export DISCOVERY_URL_OVERRIDE=$(calculateManagedServerUrl)/essbase/agent
  fi
  
else

  if [ -n "${MANAGED_SERVER_HOSTNAME_ALIAS}" ]; then
    JAVA_OPTIONS="${JAVA_OPTIONS} -DESSBASE_HOSTNAME=${MANAGED_SERVER_HOSTNAME_ALIAS}"
  fi
  
fi

export JAVA_OPTIONS

# Start in background so signal handler is in charge
${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${SERVER_NAME} $(calculateAdminServerT3Url) &
childPid=$!
wait ${childPid}
