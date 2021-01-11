#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions
checkNonRoot $(basename $0)

printVersionInfo
log "Deleting Oracle Essbase domain..."

# Process the configuration parameters
processParameters
mandatoryParameters="ORACLE_HOME DOMAIN_HOME DATABASE_CONNECT_STRING DATABASE_SCHEMA_PREFIX DATABASE_ADMIN_USERNAME DATABASE_ADMIN_PASSWORD"
checkMandatoryParameters ${mandatoryParameters}

# Ping database
if (( $DATABASE_WAIT_TIMEOUT > 0 )); then
  echo $DATABASE_ADMIN_PASSWORD | ${SCRIPT_DIR}/waitForDatabase.sh "$DATABASE_ADMIN_USERNAME" "$DATABASE_ADMIN_ROLE"
  rc=$?
  [ $rc -eq 0 ] || exit $rc
fi

domain_marker_success_file=/u01/config/.marker.domain.success
domain_marker_failed_file=/u01/config/.marker.domain.failed

log "Running RCU to drop the database schemas"
schemaComponents=(MDS WLS OPSS STB IAU IAU_APPEND IAU_VIEWER ESSBASE)

RCU_CONNECT_STRING=${DATABASE_CONNECT_STRING}
SKIP_CONNECTSTRING_VALIDATION=
tnsadminRegex="(.*)\?[Tt][Nn][Ss]_[Aa][Dd][Mm][Ii][Nn]=(.*)"
if [ "${DATABASE_TYPE}" == "ORACLE" ] && [[ ${DATABASE_CONNECT_STRING} =~ ${tnsadminRegex} ]]; then
  DATABASE_CONNECT_ALIAS=${BASH_REMATCH[1]}
  DATABASE_CONNECT_WALLET=${BASH_REMATCH[2]}
  RCU_CONNECT_STRING=jdbc:oracle:thin:@${DATABASE_CONNECT_STRING}
  SKIP_CONNECTSTRING_VALIDATION=true
fi

CMD="${ORACLE_HOME}/oracle_common/bin/rcu -silent -dropRepository"
CMD="${CMD} -databaseType ${DATABASE_TYPE} -connectString ${RCU_CONNECT_STRING} -dbUser ${DATABASE_ADMIN_USERNAME}"

if [ "${DATABASE_TYPE}" == "ORACLE" ] && [ -n "${DATABASE_ADMIN_ROLE}" ]; then
  CMD="${CMD} -dbRole ${DATABASE_ADMIN_ROLE}"
fi
  
CMD="${CMD} -schemaPrefix ${DATABASE_SCHEMA_PREFIX}"
for cmp in ${schemaComponents[@]}; do
  CMD="${CMD} -component ${cmp}"
done
CMD="${CMD} -f"

RCU_LOG_LEVEL=TRACE \
RCU_LOG_LOCATION=/u01/config/logs \
SKIP_CONNECTSTRING_VALIDATION=${SKIP_CONNECTSTRING_VALIDATION} \
${CMD} <<EOL
${DATABASE_ADMIN_PASSWORD}
EOL
rc=$?

log "Completed RCU drop command" 
if [ $rc -ne 0 ]; then
  log "RCU drop returned a non-zero error code...Ignoring..."
fi

rm -rf ${DOMAIN_HOME}
rm -rf ${ARBORPATH}
rm -rf ${domain_marker_success_file}
rm -rf ${domain_marker_failed_file}

log ""
log "##########################"
log "ESSBASE DOMAIN HAS BEEN DELETED!"
log "##########################"
log ""
