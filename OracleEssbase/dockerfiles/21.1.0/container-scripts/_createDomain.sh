#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions

function updateEssbaseCfgSetting() {
  local thekey=$1
  local newvalue=$2
  local filename="${DOMAIN_HOME}/config/fmwconfig/essconfig/essbase/essbase.cfg"
  
  log "Updating essbase.cfg: ${thekey} ${newvalue}"

  if $(grep -i -R "^[[:space:]]*[;]*[[:space:]]*${thekey}[[:space:]].*$" ${filename} > /dev/null); then
    sed -i "s|^[[:space:]]*[;]*[[:space:]]*${thekey}[[:space:]].*|${thekey} ${newvalue}|i" ${filename}
  elif $(grep -i -R "^[[:space:]]*[;]*[[:space:]]*${thekey}[[:space:]]*$" ${filename} > /dev/null); then
    sed -i "s|^[[:space:]]*[;]*[[:space:]]*${thekey}[[:space:]]*|${thekey} ${newvalue}|i" ${filename}
  else
    echo "${thekey} ${newvalue}" >> ${filename}
  fi

}

function mergeEssbaseCfgOverrides() {

  local sourceFilename=$1
  
  # These parameters are processed by the configurator so we will skip them
  local skippedParameters=( AGENTPORT \
                            AGENTSECUREPORT \
                            SERVERPORTBEGIN \
                            SERVERPORTEND \
                            ENABLESECUREMODE \
                            ENABLECLEARMODE \
                            CLIENTPREFERREDMODE \
                            WALLETPATH \
                            AUTHENTICATIONMODULE \
                          )
  local essbaseCfgLineRegex='^([a-zA-Z0-9_]+)[[:space:]]*(.*)$'
  
  log "Updating essbase.cfg settings from ${sourceFilename}"
  
  while read -r line
  do
    line=$(echo "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [[ ${line} =~ ${essbaseCfgLineRegex} ]]; then
      key=${BASH_REMATCH[1]}
      value=${BASH_REMATCH[2]}
      
      match=0
      for param in "${skippedParameters[@]}"; do
        if [[ "${param}" = "${key^^}" ]]; then
          match=1
          break
        fi
      done
      if [[ $match = 0 ]]; then
        updateEssbaseCfgSetting "${key}" "${value}"
      fi
    fi
  done < ${sourceFilename}

}

umask 027

# Defaults
MACHINE_NAME=${MACHINE_NAME_PREFIX}1

# Read credentials from stdin
read -r ADMIN_PASSWORD
read -r DATABASE_ADMIN_PASSWORD
read -r DATABASE_SCHEMA_PASSWORD
read -r IDCS_CLIENT_SECRET
read -r OPSS_WALLET_PASSWORD

# Generate schema password if not already set
if [ -z "${DATABASE_SCHEMA_PASSWORD}" ]; then
  DATABASE_SCHEMA_PASSWORD=$(generatePassword)
fi

# OPSS Wallet handling
if [ -n "${OPSS_WALLET_PASSWORD}" ]; then
  if [ -z "${OPSS_WALLET_FILE}" ]; then
    log_error "OPSS_WALLET_FILE not set"
    exit 1
  fi
  if [ ! -e "${OPSS_WALLET_FILE}" ]; then
    log_error "OPSS_WALLET_FILE not found at ${OPSS_WALLET_FILE}"
    exit 1
  fi
fi

# Essbase CFG Overrides check
if [ -n "${ESSBASE_CFG_OVERRIDES}" ]; then

  if [ ! -e "${ESSBASE_CFG_OVERRIDES}" ]; then
    log_error "Unable to find file ${ESSBASE_CFG_OVERRIDES}"
    exit 1
  fi
elif [ -e "/etc/essbase/essbase_overrides.cfg" ]; then

  ESSBASE_CFG_OVERRIDES=/etc/essbase/essbase_overrides.cfg
fi

# Make required directories
mkdir -p ${ARBORPATH}
mkdir -p ${TMP_DIR}
mkdir -p ${DOMAIN_ROOT}
mkdir -p /u01/config/logs

# We run RCU ourselves as we may have specific use cases to handle
schemaComponents=(MDS WLS OPSS STB IAU IAU_APPEND IAU_VIEWER ESSBASE)


RCU_CONNECT_STRING=${DATABASE_CONNECT_STRING}
SKIP_CONNECTSTRING_VALIDATION=
tnsadminRegex="(.*)\?[Tt][Nn][Ss]_[Aa][Dd][Mm][Ii][Nn]=(.*)"
if [ "${DATABASE_TYPE}" == "ORACLE" ] && [[ ${DATABASE_CONNECT_STRING} =~ ${tnsadminRegex} ]]; then
  DATABASE_ALIAS=${BASH_REMATCH[1]}
  DATABASE_WALLET_LOCATION=${BASH_REMATCH[2]}
  RCU_CONNECT_STRING=jdbc:oracle:thin:@${DATABASE_ALIAS}?TNS_ADMIN=${DATABASE_WALLET_LOCATION}
  SKIP_CONNECTSTRING_VALIDATION=true
fi

if [ -z "${OPSS_WALLET_FILE}" ] && [ "${DROP_SCHEMA}" == "TRUE" ]; then

  log "Running RCU to drop the database schemas"

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

  CREATE_SCHEMA=TRUE
fi


if [ -z "${OPSS_WALLET_FILE}" ] && [ "${CREATE_SCHEMA}" == "TRUE" ]; then

  log "Running RCU to create the database schemas"

  CMD="${ORACLE_HOME}/oracle_common/bin/rcu -silent -createRepository"
  CMD="${CMD} -databaseType ${DATABASE_TYPE} -connectString ${RCU_CONNECT_STRING} -dbUser ${DATABASE_ADMIN_USERNAME}"

  if [ "${DATABASE_TYPE}" == "ORACLE" ] && [ -n "${DATABASE_ADMIN_ROLE}" ]; then
    CMD="${CMD} -dbRole ${DATABASE_ADMIN_ROLE}"
  fi
  
  CMD="${CMD} -useSamePasswordForAllSchemaUsers true"
  CMD="${CMD} -schemaPrefix ${DATABASE_SCHEMA_PREFIX}"
  for cmp in ${schemaComponents[@]}; do
    CMD="${CMD} -component ${cmp}"
     
    if [ "${DATABASE_TYPE}" == "ORACLE" ] && [ -n "${DATABASE_SCHEMA_TABLESPACE}" ]; then
      CMD="${CMD} -tablespace ${DATABASE_SCHEMA_TABLESPACE}"
    fi

    if [ "${DATABASE_TYPE}" == "ORACLE" ] && [ -n "${DATABASE_SCHEMA_TEMP_TABLESPACE}" ]; then
      CMD="${CMD} -tempTablespace ${DATABASE_SCHEMA_TEMP_TABLESPACE}"
    fi

  done
  CMD="${CMD} -f"

  RCU_LOG_LEVEL=TRACE \
  RCU_LOG_LOCATION=/u01/config/logs \
  SKIP_CONNECTSTRING_VALIDATION=${SKIP_CONNECTSTRING_VALIDATION} \
  ${CMD} <<EOL
${DATABASE_ADMIN_PASSWORD}
${DATABASE_SCHEMA_PASSWORD}
EOL
  rc=$?

  if [ $rc -ne 0 ]; then
    log_error "RCU create failed with error code $rc...Exiting..."
    exit $rc
  fi

  log "Completed RCU create command"
fi


if [ "${DATABASE_TYPE}" == "ORACLE" ]; then
  DATABASE_TYPE_VALUE=DB_ORACLE
elif [ "${DATABASE_TYPE}" == "SQLSERVER" ]; then
  DATABASE_TYPE_VALUE=DB_SQLSERVER
else
  log_error "Unknown database type ${DATABASE_TYPE}"
  exit 1
fi


# Write out input.cfg for the config script
responseFile=$(mktemp "/u01/tmp/create_XXXXXXXXXX.rsp")
trap 'rm -rf -- "$responseFile"' EXIT

cat > ${responseFile} <<EOF
DOMAIN_NAME=${DOMAIN_NAME}
DOMAIN_ROOT=${DOMAIN_ROOT}
ARBORPATH=${ARBORPATH}
ADMIN_USERNAME=${ADMIN_USERNAME}
CREATE_DATABASE_SCHEMA=USE_EXISTING
DATABASE_TYPE=${DATABASE_TYPE_VALUE}
DATABASE_CONNECT_STRING=${DATABASE_CONNECT_STRING}
DATABASE_ADMIN_USERNAME=${DATABASE_ADMIN_USERNAME}
DATABASE_ADMIN_ROLE=${DATABASE_ADMIN_ROLE}
DATABASE_PREFIX=${DATABASE_SCHEMA_PREFIX}
MACHINE_NAME=${MACHINE_NAME}
NODE_MANAGER_PORT=${NODE_MANAGER_PORT}
NODE_MANAGER_LISTEN_ADDRESS=127.0.0.1
ADMIN_SERVER_PORT=${ADMIN_SERVER_PORT}
ADMIN_SERVER_SSL_PORT=${ADMIN_SERVER_SSL_PORT}
ADMIN_SERVER_LISTEN_ADDRESS=
MANAGED_SERVER_PORT=${MANAGED_SERVER_PORT}
MANAGED_SERVER_SSL_PORT=${MANAGED_SERVER_SSL_PORT}
MANAGED_SERVER_LISTEN_ADDRESS=
AGENT_PORT=${AGENT_PORT}
AGENT_SSL_PORT=${AGENT_SSL_PORT}
ESSBASE_SERVER_MIN_PORT=${ESSBASE_SERVER_MIN_PORT}
ESSBASE_SERVER_MAX_PORT=${ESSBASE_SERVER_MAX_PORT}
ENABLE_EAS=${ENABLE_EAS}
EAS_SERVER_PORT=${EAS_SERVER_PORT}
EAS_SERVER_SSL_PORT=${EAS_SERVER_SSL_PORT}
SECURE_MODE=${SECURE_MODE}
START_SERVERS=FALSE
EOF

log ""
log "Running Essbase configuration tool"
CONFIG_JVM_ARGS="-Djava.io.tmpdir=${TMP_DIR} -Djava.security.egd=file:/dev/./urandom" \
${ORACLE_HOME}/essbase/bin/config.sh -mode=silent -responseFile=${responseFile} -log=/u01/config/logs/config_essbase.log -log_priority=INFO <<EOL
${ADMIN_PASSWORD}
${DATABASE_SCHEMA_PASSWORD}
EOL
rc=$?

rm -rf ${responseFile}
trap - EXIT

if [ $rc -ne 0 ]; then
  log_error "Essbase configuration failed with error code $rc"
  exit $rc
fi

# Clean up
rm -rf ${DOMAIN_HOME}/servers/AdminServer/security ${DOMAIN_HOME}/servers/AdminServer/logs ${DOMAIN_HOME}/servers/AdminServer/tmp
rm -rf ${DOMAIN_HOME}/servers/essbase_server1/security ${DOMAIN_HOME}/servers/essbase_server1/logs ${DOMAIN_HOME}/servers/essbase_server1/tmp

# Post configuration updates
log ""
log "Starting post configuration updates"
WLST_PROPERTIES="-Dwlst.offline.log.priority=info -Dwlst.offline.log=/u01/config/logs/update_essbase_domain.log" \
${SCRIPT_DIR}/run-wlst.sh ${SCRIPT_DIR}/wlst/update_essbase_domain.py ${DOMAIN_HOME}
rc=$?
if [ $rc -ne 0 ]; then
  log_error "Essbase configuration failed with error code $rc"
  exit $rc
fi

# Process essbase.cfg overrides
updateEssbaseCfgSetting "CRASHDUMP" "TRUE"
updateEssbaseCfgSetting "CRASHDUMPLOCATION" "${CRASHDUMP_LOCATION}"

if [ -n "${ESSBASE_CFG_OVERRIDES}" ]; then
  mergeEssbaseCfgOverrides ${ESSBASE_CFG_OVERRIDES}
fi

# IDCS Support
if [ "${IDENTITY_PROVIDER^^}" == "IDCS" ]; then

  # Post configuration updates
  WLST_PROPERTIES="-Dwlst.offline.log.priority=info -Dwlst.offline.log=/u01/config/logs/enable_idcs_mode.log" \
  ${SCRIPT_DIR}/run-wlst.sh ${SCRIPT_DIR}/wlst/enable_idcs_mode.py ${DOMAIN_HOME} ${IDCS_HOST} ${IDCS_PORT} $(novalueIfEmpty) ${IDCS_TENANT} $(novalueIfEmpty ${IDCS_CLIENT_TENANT}) ${IDCS_CLIENT_ID} <<EOF
${IDCS_CLIENT_SECRET}
EOF
  rc=$?
  if [ $rc -ne 0 ]; then
    log_error "Essbase configuration failed with error code $rc"
    exit $rc
  fi

fi


# Write the overrides for the env, has to be done here because
# setUserOverrides is too late
cat >> ${DOMAIN_HOME}/bin/setEssbaseEnvOverrides.sh <<EOF

# Override DISCOVERY_URL to always lookup the host locally
if [ "${SECURE_MODE}" == "TRUE" ]; then
  export DISCOVERY_URL=https://\${HOSTNAME}:${MANAGED_SERVER_SSL_PORT}/essbase/agent
else
  export DISCOVERY_URL=http://\${HOSTNAME}:${MANAGED_SERVER_PORT}/essbase/agent
fi

if [ -n "\${DISCOVERY_URL_OVERRIDE}" ]; then
  export DISCOVERY_URL=\${DISCOVERY_URL_OVERRIDE}
fi
EOF

# Add additional cluster nodes
if [ ${ESSBASE_CLUSTER_SIZE} -gt 1 ]; then

  # Update CFG to enable failover mode
  updateEssbaseCfgSetting "FailoverMode" "true"
  
  node_index=2
  while [[ $node_index -le ${ESSBASE_CLUSTER_SIZE} ]]
  do
    WLST_PROPERTIES="-Dwlst.offline.log.priority=info -Dwlst.offline.log=/u01/config/logs/add_essbase_cluster_node_${node_index}.log" \
    ${SCRIPT_DIR}/run-wlst.sh ${SCRIPT_DIR}/wlst/add_essbase_cluster_node.py ${DOMAIN_HOME} ${node_index} ${MACHINE_NAME_PREFIX} $(novalueIfEmpty) ${NODE_MANAGER_PORT} $(novalueIfEmpty) ${MANAGED_SERVER_PORT} ${MANAGED_SERVER_SSL_PORT}
    rc=$?

    if [ $rc -ne 0 ]; then
      log_error "Essbase configuration failed with error code $rc"
      exit $rc
    fi

    node_index=$[$node_index + 1]
  done

fi
