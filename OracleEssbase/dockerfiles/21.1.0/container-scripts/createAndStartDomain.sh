#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions
checkNonRoot $(basename $0)

printVersionInfo
log "Starting Oracle Essbase domain..."

# Check whether container has enough memory
if [ $(cat /sys/fs/cgroup/memory/memory.limit_in_bytes) -lt 6442450944 ]; then
  log_error "Error: The container doesn't have enough memory allocated."
  log_error "This container should have at least 6GB of memory."
  log_error "You currently only have $((`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`/1024/1024/1024)) GB allocated to the container."
  exit 1
fi

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

# Start the servers using the standard script
# This needs to be started in the background to avoid issues with the node manager
# and graceful shutdown.
statusfile=/tmp/notifyfifo.$$
rm -rf "${statusfile}"
mkfifo "${statusfile}" || exit 1
trap 'rm -rf -- "$statusfile"' EXIT

${DOMAIN_HOME}/esstools/bin/start.sh <${statusfile} &
startPid=$!
cat >${statusfile} <<EOL
${ADMIN_USERNAME}
${ADMIN_PASSWORD}
EOL
wait $startPid
rc=$?

if [ $rc -eq 0 ]; then
  ${SCRIPT_DIR}/healthcheck.sh
  rc=$?
fi

# Check the health of the service
if [ $rc -eq 0 ]; then
  log ""
  log "##########################"
  log "ESSBASE IS READY FOR USE!"
  log "##########################"
  log ""
else
  log_error "#####################################"
  log_error "########### E R R O R ###############"
  log_error "ESSBASE SETUP WAS NOT SUCCESSFUL!"
  log_error "Please check output for further info!"
  log_error "########### E R R O R ###############"
  log_error "#####################################"
  exit 1
fi

# Signal handlers
nodeManagerPid=$(cat ${DOMAIN_HOME}/nodemanager/nodemanager.process.id)
childPid=0
_stopDomain() {
  log "Shutting down the container!"
  ${SCRIPT_DIR}/_stopDomain.sh
  if [ ${childPid} -ne 0 ]; then
    kill ${childPid} 2> /dev/null
  fi
}

trap '_stopDomain' SIGINT SIGTERM

# Tail the server log file and attach the nodemanager.process.id
touch ${DOMAIN_HOME}/servers/essbase_server1/logs/essbase_server1.out
tail --pid=${nodeManagerPid} -f ${DOMAIN_HOME}/servers/essbase_server1/logs/essbase_server1.out &
childPid=$!
wait ${childPid}
