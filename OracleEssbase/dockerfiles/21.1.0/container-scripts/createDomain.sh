#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions
checkNonRoot $(basename $0)

printVersionInfo
log "Creating Oracle Essbase domain..."

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

domain_marker_success_file=/u01/config/.marker.domain.success
domain_marker_failed_file=/u01/config/.marker.domain.failed

if [ -e ${DOMAIN_HOME} ]; then
  log "Removing existing ${DOMAIN_HOME}"
  rm -rf ${DOMAIN_HOME}
fi

if [ -e ${ARBORPATH} ]; then
  log "Removing existing ${ARBORPATH}"
  rm -rf ${ARBORPATH}
fi

if [ -e ${domain_marker_success_file} ]; then 
  rm -rf ${domain_marker_success_file}
fi

if [ -e ${domain_marker_failed_file} ]; then 
  rm -rf ${domain_marker_failed_file}
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
  log ""
  log "##########################"
  log "ESSBASE DOMAIN CONFIGURATION FAILED!"
  log "##########################"
  log ""
  exit $rc
else  
  echo $rc > "${domain_marker_success_file}"
  log ""
  log "##########################"
  log "ESSBASE DOMAIN HAS BEEN CONFIGURED!"
  log "##########################"
  log ""
fi
