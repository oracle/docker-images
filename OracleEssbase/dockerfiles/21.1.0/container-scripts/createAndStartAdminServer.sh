#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions
checkNonRoot $(basename $0)

printVersionInfo
log "Starting WebLogic AdminServer..."

# Process the configuration parameters
processParameters
mandatoryParameters="ORACLE_HOME DOMAIN_HOME ARBORPATH ADMIN_USERNAME ADMIN_PASSWORD DATABASE_TYPE DATABASE_CONNECT_STRING DATABASE_SCHEMA_PREFIX"
if [ "${CREATE_SCHEMA}" == "TRUE" ]; then
   mandatoryParameters="${mandatoryParameters} DATABASE_ADMIN_USERNAME DATABASE_ADMIN_PASSWORD" 
else
   mandatoryParameters="${mandatoryParameters} DATABASE_SCHEMA_PASSWORD" 
fi
if [ -n "${OPSS_WALLET_PASSWORD}" ] || [ -n "${OPSS_WALLET_FILE}" ]; then
   mandatoryParameters="${mandatoryParameters} OPSS_WALLET_PASSWORD OPSS_WALLET_FILE"
fi
if [ "${IDENTITY_PROVIDER}" == "IDCS" ]; then
   mandatoryParameters="${mandatoryParameters} IDCS_CLIENT_ID IDCS_CLIENT_SECRET IDCS_TENANT"
fi
checkMandatoryParameters ${mandatoryParameters}

# Ping database
if (( $DATABASE_WAIT_TIMEOUT > 0 )); then

  if [ "${CREATE_SCHEMA}" == "TRUE" ]; then
    echo $DATABASE_ADMIN_PASSWORD | ${SCRIPT_DIR}/waitForDatabase.sh "$DATABASE_ADMIN_USERNAME" "$DATABASE_ADMIN_ROLE"
    rc=$?
  else 
    echo $DATABASE_SCHEMA_PASSWORD | ${SCRIPT_DIR}/waitForDatabase.sh "${DATABASE_SCHEMA_PREFIX}_ESSBASE"
    rc=$?
  fi
  
  [ $rc -eq 0 ] || exit $rc
fi

# check whether it is the first time this container is up
domain_marker_success_file=/u01/config/.marker.domain.success
domain_marker_failed_file=/u01/config/.marker.domain.failed
if [ ! -e ${domain_marker_success_file} ]; then
  rm -rf ${domain_marker_failed_file}
  if [ -e /u01/config ]; then
    rm -rf /u01/config/*
  fi

  ADMIN_USERNAME=${ADMIN_USERNAME} \
  DATABASE_ADMIN_USERNAME=${DATABASE_ADMIN_USERNAME} \
  IDCS_CLIENT_ID=${IDCS_CLIENT_ID} \
  ${SCRIPT_DIR}/_createDomain.sh <<EOL
${ADMIN_PASSWORD}
${DATABASE_ADMIN_PASSWORD}
${DATABASE_SCHEMA_PASSWORD}
${IDCS_CLIENT_SECRET}
${OPSS_WALLET_PASSWORD}
EOL

  rc=$?
  if [ $rc -ne 0 ]; then
    echo $rc > "${domain_marker_failed_file}"
    log_error "Failed with error code $rc"
    exit $rc
  fi
  echo $rc > "${domain_marker_success_file}"
fi

# Create the security file to start the server(s) without the password prompt
log "Writing boot.properties file for AdminServer"
${SCRIPT_DIR}/run-wlst.sh ${SCRIPT_DIR}/wlst/write_server_boot_properties.py ${DOMAIN_HOME} AdminServer > /dev/null 2>&1 <<EOL
${ADMIN_USERNAME}
${ADMIN_PASSWORD}
EOL

# Signal handlers
childPid=0
_stopAdminServer() {
  log "Shutting down the container!"
  if [ ${childPid} -ne 0 ]; then
     echo ${ADMIN_PASSWORD} | ${SCRIPT_DIR}/_stopServer.sh AdminServer ${ADMIN_USERNAME} 
     kill -9 ${childPid} 2> /dev/null
  fi
}

trap '_stopAdminServer' SIGINT SIGTERM

# Start Admin Server and tail the logs
JAVA_OPTIONS="-XX:+PrintFlagsFinal -Dweblogic.StdoutDebugEnabled=false"
export JAVA_OPTIONS
${DOMAIN_HOME}/startWebLogic.sh &
childPid=$!
wait ${childPid}
