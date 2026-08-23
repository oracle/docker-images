#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: April, 2024
# Author:ishaan.desai@oracle.com
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

declare -x ORACLE_PWD
declare -x ORACLE_SID
declare -x PRIMARY_DB_CONNECT_STR
declare -x PRIMARY_PDB_CONNECT_STR
declare -x PRIMARY_DB_HOST
declare -x PRIMARY_DB_PORT
declare -x PRIMARY_DB_NAME
declare -x PRIMARY_DB_UNIQUE_NAME
declare -x PRIMARY_PDB_NAME
declare -x PRIMARY_IS_RAC
declare -x TRUE_CACHE_LISTENER_SERVICE_NAME
declare -x TRUE_CACHE_CALLBACK_SERVICE_NAME
declare -x DEBUG="TRUE"
declare -x pdbExists
declare -x tcInstanceCreated
declare -x DEFERRED_PRIMARY_SCHEDULER_WARNING=""

export NOW=$(date +"%Y%m%d%H%M")
export TMP_LOC=${TMP_LOC:-"/var/tmp"}
export TRUECACHE_SERVICE_START_TIMEOUT_SECONDS=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS:-600}
export TRUECACHE_ASSOCIATION_LOG_INTERVAL_SECONDS=${TRUECACHE_ASSOCIATION_LOG_INTERVAL_SECONDS:-60}
export PRIMARY_DB_USER=${PRIMARY_DB_USER:-"sys as sysdba"}
export PRIMARY_TC_SERVICE_SCRIPT_PATH=${PRIMARY_TC_SERVICE_SCRIPT_PATH:-"/home/oracle/configure-primary-truecache-service.sh"}
export PRIMARY_TC_SERVICE_WALLET_PATH=${PRIMARY_TC_SERVICE_WALLET_PATH:-""}
export PRIMARY_TC_SERVICE_CREDENTIAL_NAME=${PRIMARY_TC_SERVICE_CREDENTIAL_NAME:-""}
export DB_PWD_FILE=${DB_PWD_FILE:-"oracle_pwd"}
export PWD_KEY=${PWD_KEY:-"oracle_pwd_privkey"}
export LOGDIR=${LOGDIR:-"/var/tmp"}
export LOGFILE="${LOGDIR}/tc_${NOW}.log"
export STD_OUT_FILE="/proc/1/fd/1"
export ORADATA="/opt/oracle/oradata"
export STD_ERR_FILE="/proc/1/fd/2"
declare -x SECRET_VOLUME='/run/secrets'      ## Secret Volume
export TOP_PID=$$
rm -f $LOGFILE

#################################### Print and Exit Functions Begin Here #######################

function error_exit {
 local NOW=$(date +"%m-%d-%Y %T %Z")
 echo "${NOW} : ${PROGNAME}: ${1:-"Unknown Error"}" | tee -a $LOGFILE > $STD_OUT_FILE
 kill -s TERM $TOP_PID
}

function print_message {
   local NOW=$(date +"%m-%d-%Y %T %Z")
   # Display  message and return
   echo "${NOW} : ${PROGNAME} : ${1:-"Unknown Message"}" | tee -a $LOGFILE > $STD_OUT_FILE
   return $?
}

#################################### Print and Exit Functions End Here #######################

# Function to delete a file
function delFile {
   local file_name=$1
   if [ -f "${file_name}" ]; then
      rm -f "${file_name}"
   fi
}

# Escape a string for use inside a SQL single-quoted literal.
function sqlEscapeLiteral {
   printf '%s' "$1" | sed "s/'/''/g"
}

function normalizeServiceName {
   local value
   value=$(printf '%s' "$1" | xargs)
   printf '%s' "${value^^}"
}

function formatPendingAssociationValue {
  local value

  value=$(printf '%s' "${1:-}" | xargs)
  if [ -z "${value}" ]; then
    printf '%s' "PENDING_PRIMARY_UPDATE"
    return 0
  fi

  printf '%s' "${value}"
}

function hasTrueCacheDBCredentialsWallet {
  [ -n "${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR:-}" ] && [ -f "${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR}/ewallet.p12" ]
}

function ensurePrimaryWalletTnsAdmin {
  local tns_admin_dir

  if ! hasTrueCacheDBCredentialsWallet; then
    return 1
  fi

  if [ -n "${TRUECACHE_PRIMARY_WALLET_TNS_ADMIN:-}" ] && [ -f "${TRUECACHE_PRIMARY_WALLET_TNS_ADMIN}/sqlnet.ora" ]; then
    export TNS_ADMIN="${TRUECACHE_PRIMARY_WALLET_TNS_ADMIN}"
    return 0
  fi

  tns_admin_dir="${TMP_LOC}/truecache-primary-wallet-${TOP_PID}"
  mkdir -p "${tns_admin_dir}" || return 1
  cat > "${tns_admin_dir}/sqlnet.ora" <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = ${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR})))
SQLNET.WALLET_OVERRIDE = TRUE
NAMES.DIRECTORY_PATH = (EZCONNECT, TNSNAMES, HOSTNAME)
SQLNET.EXPIRE_TIME=3
EOF
  export TRUECACHE_PRIMARY_WALLET_TNS_ADMIN="${tns_admin_dir}"
  export TNS_ADMIN="${tns_admin_dir}"
  print_message "Using wallet-backed TNS_ADMIN=${TNS_ADMIN} for primary database connectivity."
}

function buildPrimaryConnectStr {
  local connect_target=$1
  local user
  local priv

  user="${PRIMARY_DB_USER%% as *}"
  if [[ "${PRIMARY_DB_USER}" == *" as "* ]]; then
    priv=" as ${PRIMARY_DB_USER#* as }"
  else
    priv=""
  fi

  if [ -n "${ORACLE_PWD:-}" ]; then
    printf '%s/%s@%s%s\n' "${user}" "${ORACLE_PWD}" "${connect_target}" "${priv}"
    return 0
  fi

  if ensurePrimaryWalletTnsAdmin; then
    printf '/@%s%s\n' "${connect_target}" "${priv}"
    return 0
  fi

  return 1
}

function isTrueCacheServicePresent {
  local service_name

  service_name=$(normalizeServiceName "$(getSQLOUTPUT "ALTER SESSION SET CONTAINER=${PRIMARY_PDB_NAME};
SELECT name FROM cdb_services WHERE upper(name)='${TRUE_CACHE_DB_APP_SVC}';" "/ as sysdba")")
  [ "${service_name}" == "${TRUE_CACHE_DB_APP_SVC}" ]
}

# Function to execute a sql script or sql query on a database
function getSQLOUTPUT {
  local sql_query=$1
  local connect_str=$2
  local type=$3
  local sql_script=$4
  local output
  if [ -z "${sql_query}" ]; then
    print_message "Empty sql_query passed to sqlplus. Operation Failed"
  fi

  if [ -z "${connect_str}" ]; then
      error_exit "Empty connect_str passed to sqlplus. Operation Failed"
  fi

  if [ -z "${type}" ]; then
      type='notSet'
  fi

  if [ -z "${sql_script}" ]; then
    sql_script='notSet'
  fi


  if  [ "${type}" == "sqlScript" ] && [ -f "${sql_script}" ]; then
    print_message "Executing sql script using connect string"
    output=$( "$ORACLE_HOME"/bin/sqlplus -s "$connect_str" << EOF | tee -a "$LOGFILE"
        set define off heading off verify off echo off PAGESIZE 0
        @$sql_script
        exit
EOF
)
  else
  output=$( "$ORACLE_HOME"/bin/sqlplus -s "${connect_str}" <<EOF
        set define off heading off feedback off verify off echo off PAGESIZE 0
        $sql_query
        exit
EOF
)
  fi
  echo  "${output}"
}

function waitForTrueCachePDBOpen {
  local timeout_seconds
  local elapsed
  local open_mode
  local normalized_state
  local next_log_elapsed
  timeout_seconds=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS}
  elapsed=0
  next_log_elapsed=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    open_mode=$(getSQLOUTPUT "SELECT open_mode FROM v\$pdbs WHERE name='${PRIMARY_PDB_NAME}';" "/ as sysdba" | xargs)
    normalized_state="${open_mode}"

    if [ "${open_mode}" == "READ ONLY" ]; then
      print_message "True Cache PDB ${PRIMARY_PDB_NAME} is open READ ONLY."
      return 0
    fi

    if printf '%s\n' "${open_mode}" | grep -Eq 'ORA-00604|ORA-61857|ORA-61874'; then
      normalized_state="READ_ONLY_TRANSITION_IN_PROGRESS"
    fi

    if [ "${elapsed}" -ge "${next_log_elapsed}" ]; then
      print_message "Waiting for True Cache PDB ${PRIMARY_PDB_NAME} to report READ ONLY. current=[${normalized_state}] elapsed=${elapsed}s"
      next_log_elapsed=$((elapsed + 15))
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  print_message "Timed out waiting for True Cache PDB ${PRIMARY_PDB_NAME} to open READ ONLY."
  return 1
}

function waitForTrueCacheServiceActive {
  local timeout_seconds
  local elapsed
  local active_name
  local next_log_elapsed
  timeout_seconds=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS}
  elapsed=0
  next_log_elapsed=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    active_name=$(normalizeServiceName "$(getSQLOUTPUT "SELECT name FROM v\$active_services WHERE upper(name)='${TRUE_CACHE_DB_APP_SVC}';" "/ as sysdba")")

    if [ "${active_name}" == "${TRUE_CACHE_DB_APP_SVC}" ]; then
      print_message "True Cache service ${TRUE_CACHE_DB_APP_SVC} is active locally."
      return 0
    fi

    if [ "${elapsed}" -ge "${next_log_elapsed}" ]; then
      print_message "Waiting for True Cache service ${TRUE_CACHE_DB_APP_SVC} to become active. current=[${active_name}] elapsed=${elapsed}s"
      next_log_elapsed=$((elapsed + 15))
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  print_message "Timed out waiting for True Cache service ${TRUE_CACHE_DB_APP_SVC} to become active."
  return 1
}

function isTrueCacheServiceActive {
  local active_name

  active_name=$(normalizeServiceName "$(getSQLOUTPUT "SELECT name FROM v\$active_services WHERE upper(name)='${TRUE_CACHE_DB_APP_SVC}';" "/ as sysdba")")
  [ "${active_name}" == "${TRUE_CACHE_DB_APP_SVC}" ]
}

function waitForPrimaryTrueCacheAssociation {
  local timeout_seconds
  local elapsed
  local association_name
  local association_log_value
  local transport_status
  local log_interval_seconds
  local next_log_elapsed

  timeout_seconds=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS}
  log_interval_seconds=${TRUECACHE_ASSOCIATION_LOG_INTERVAL_SECONDS}
  if ! [[ "${log_interval_seconds}" =~ ^[0-9]+$ ]] || [ "${log_interval_seconds}" -le 0 ]; then
    log_interval_seconds=60
  fi
  elapsed=0
  next_log_elapsed=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    association_name=$(getPrimaryTrueCacheAssociation)
    transport_status=$(getPrimaryTrueCacheTransportStatus)

    if [ "${association_name}" == "${TRUE_CACHE_DB_APP_SVC}" ]; then
      print_message "Primary service ${PRIMARY_DB_APP_SVC} is associated with True Cache service ${TRUE_CACHE_DB_APP_SVC}."
      return 0
    fi

    if [ -z "${association_name}" ] && [ -n "${transport_status}" ]; then
      print_message "Primary transport to True Cache ${TRUEDB_UNIQUE_NAME} is active despite missing association metadata. transport=[${transport_status}]"
      return 0
    fi

    if [ "${elapsed}" -ge "${next_log_elapsed}" ]; then
      association_log_value=$(formatPendingAssociationValue "${association_name}")
      print_message "Waiting for primary association metadata to become visible PRIMARY_SERVICE=${PRIMARY_DB_APP_SVC} TRUECACHE_SERVICE=${TRUE_CACHE_DB_APP_SVC}. current=[${association_log_value}] elapsed=${elapsed}s"
      next_log_elapsed=$((elapsed + log_interval_seconds))
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  return 1
}

function resolveTrueCacheListenerServiceName {
  local output
  local resolved_name

  if [ -n "${TRUE_CACHE_LISTENER_SERVICE_NAME:-}" ]; then
    print_message "Using cached True Cache listener service ${TRUE_CACHE_LISTENER_SERVICE_NAME}."
    return 0
  fi

  output=$(getSQLOUTPUT "SELECT value FROM v\$parameter WHERE name='service_names';" "/ as sysdba")
  output=$(echo "${output}" | tr '\n' ' ' | xargs)
  resolved_name=$(echo "${output}" | tr ',' '\n' | sed -n '/./{s/^[[:space:]]*//;s/[[:space:]]*$//;p;q;}')
  if [ -n "${resolved_name}" ]; then
    TRUE_CACHE_LISTENER_SERVICE_NAME="${resolved_name}"
    print_message "Resolved True Cache listener service from service_names=${TRUE_CACHE_LISTENER_SERVICE_NAME}."
    return 0
  fi

  output=$(getSQLOUTPUT "SELECT global_name FROM global_name;" "/ as sysdba")
  output=$(echo "${output}" | xargs)
  if [ -n "${output}" ]; then
    TRUE_CACHE_LISTENER_SERVICE_NAME="${output}"
    print_message "Resolved True Cache listener service from global_name=${TRUE_CACHE_LISTENER_SERVICE_NAME}."
    return 0
  fi

  TRUE_CACHE_LISTENER_SERVICE_NAME="${TRUEDB_UNIQUE_NAME:-${ORACLE_SID}}"
  print_message "Falling back to derived True Cache listener service ${TRUE_CACHE_LISTENER_SERVICE_NAME}."
}

function resolveTrueCacheCallbackServiceName {
  local primary_service
  local callback_domain

  if [ -n "${TRUE_CACHE_CALLBACK_SERVICE_NAME:-}" ]; then
    print_message "Using cached True Cache callback service ${TRUE_CACHE_CALLBACK_SERVICE_NAME}."
    return 0
  fi

  if [ -n "${TRUE_CACHE_CALLBACK_SERVICE:-}" ]; then
    TRUE_CACHE_CALLBACK_SERVICE_NAME="${TRUE_CACHE_CALLBACK_SERVICE}"
    print_message "Using caller-provided True Cache callback service ${TRUE_CACHE_CALLBACK_SERVICE_NAME}."
    return 0
  fi

  primary_service="${PRIMARY_DB_CONN_STR#*/}"
  if [ "${primary_service}" != "${PRIMARY_DB_CONN_STR}" ] && [[ "${primary_service}" == *.* ]]; then
    callback_domain="${primary_service#*.}"
    TRUE_CACHE_CALLBACK_SERVICE_NAME="${TRUEDB_UNIQUE_NAME}.${callback_domain}"
    print_message "Derived True Cache callback service ${TRUE_CACHE_CALLBACK_SERVICE_NAME} from primary connect string domain ${callback_domain}."
    return 0
  fi

  TRUE_CACHE_CALLBACK_SERVICE_NAME="${TRUEDB_UNIQUE_NAME:-${ORACLE_SID}}"
  print_message "Falling back to derived True Cache callback service ${TRUE_CACHE_CALLBACK_SERVICE_NAME}."
}

function waitForTrueCacheListenerConnectable {
  local timeout_seconds
  local elapsed
  local output
  local wait_logged
  local connect_target
  timeout_seconds=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS}
  elapsed=0
  wait_logged=0
  resolveTrueCacheListenerServiceName
  # This is a local readiness probe inside the True Cache pod. Keep the host on
  # localhost so the check stays independent of external DNS, but use the
  # actual listener-registered CDB service because DBCA on the primary also
  # needs a listener-based callback target, not a BEQ-only connection.
  connect_target="localhost:1521/${TRUE_CACHE_LISTENER_SERVICE_NAME}"

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    output=$("${ORACLE_HOME}/bin/tnsping" "//${connect_target}" 2>/dev/null || true)
    output=$(printf '%s\n' "${output}" | xargs)

    if printf '%s\n' "${output}" | grep -q "OK ("; then
      print_message "True Cache listener target ${connect_target} is connectable."
      return 0
    fi

    if [ "${wait_logged}" -eq 0 ]; then
      print_message "Waiting for True Cache listener target ${connect_target} to become connectable. current=[${output}] elapsed=${elapsed}s"
      wait_logged=1
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  print_message "Timed out waiting for True Cache listener target ${connect_target} to become connectable."
  return 1
}

function waitForPrimaryServiceConnectable {
  local timeout_seconds
  local elapsed
  local output
  local wait_logged
  timeout_seconds=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS}
  elapsed=0
  wait_logged=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    output=$(getSQLOUTPUT "SELECT 'READY' FROM dual;" "${PRIMARY_PDB_CONNECT_STR}" | xargs)

    if [ "${output}" == "READY" ]; then
      print_message "Primary service ${PRIMARY_DB_APP_SVC} is connectable through the listener."
      return 0
    fi

    if [ "${wait_logged}" -eq 0 ]; then
      print_message "Waiting for primary service ${PRIMARY_DB_APP_SVC} to register with the listener. current=[${output}] elapsed=${elapsed}s"
      wait_logged=1
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  print_message "Timed out waiting for primary service ${PRIMARY_DB_APP_SVC} to become listener-connectable."
  return 1
}

# Function to set the connect string to the primary database
function setConnectStr {
  local primary_pdb_connect_target="${PRIMARY_DB_APP_SVC:-${PRIMARY_PDB_NAME}}"
  local primary_pdb_ezconnect_target="${PRIMARY_DB_HOST}:${PRIMARY_DB_PORT}/${primary_pdb_connect_target}"
  local db_connect_str
  local pdb_connect_str

  db_connect_str=$(buildPrimaryConnectStr "${PRIMARY_DB_CONN_STR}") || error_exit "Unable to build primary CDB connect string for ${PRIMARY_DB_CONN_STR}. Provide dbCredentialsWallet or ORACLE_PWD."
  pdb_connect_str=$(buildPrimaryConnectStr "${primary_pdb_ezconnect_target}") || error_exit "Unable to build primary PDB connect string for ${primary_pdb_ezconnect_target}. Provide dbCredentialsWallet or ORACLE_PWD."
  print_message "Using primary CDB connect target ${PRIMARY_DB_CONN_STR}."
  print_message "Using primary PDB connect target ${primary_pdb_ezconnect_target} for PDB ${PRIMARY_PDB_NAME}."
  PRIMARY_DB_CONNECT_STR=${db_connect_str}
  PRIMARY_PDB_CONNECT_STR=${pdb_connect_str}
}

# Resolve the primary CDB name even when PRIMARY_DB_CONN_STR points at a service.
function resolvePrimaryDbName {
  local connect_str
  local output
  local resolved_db_name
  local resolved_db_unique_name
  local cluster_database
  local sanitized_output

  connect_str=$(buildPrimaryConnectStr "${PRIMARY_DB_CONN_STR}") || error_exit "Unable to connect to PRIMARY_DB_CONN_STR ${PRIMARY_DB_CONN_STR}. Provide dbCredentialsWallet or ORACLE_PWD."
  output=$(getSQLOUTPUT "SELECT name || ':' || db_unique_name || ':' || lower((SELECT value FROM v\$parameter WHERE name='cluster_database')) FROM v\$database;" "${connect_str}")
  output=$(echo "${output}" | xargs)
  sanitized_output=$(printf '%s' "${output}" | tr -d '\r')

  if printf '%s\n' "${sanitized_output}" | grep -Eq '(^ERROR:|ORA-[0-9]{5}|SP2-[0-9]{4})'; then
    error_exit "Unable to resolve primary database metadata from ${PRIMARY_DB_CONN_STR}. sqlplus returned [${sanitized_output}]"
  fi

  resolved_db_name=$(echo "${output}" | cut -d ':' -f 1)
  resolved_db_unique_name=$(echo "${output}" | cut -d ':' -f 2)
  cluster_database=$(echo "${output}" | cut -d ':' -f 3)

  if [ -z "${resolved_db_name}" ]; then
    error_exit "Unable to resolve PRIMARY_DB_NAME from PRIMARY_DB_CONN_STR ${PRIMARY_DB_CONN_STR}. Exiting..."
  fi

  if [ -n "${PRIMARY_DB_NAME}" ]; then
    print_message "PRIMARY_DB_NAME requested as ${PRIMARY_DB_NAME}"
    if [ "${PRIMARY_DB_NAME^^}" != "${resolved_db_name^^}" ]; then
      print_message "PRIMARY_DB_NAME ${PRIMARY_DB_NAME} does not match primary metadata db_name=${resolved_db_name} db_unique_name=${resolved_db_unique_name}. Using db_name ${resolved_db_name} for DBCA sourceDB."
    fi
  fi

  PRIMARY_DB_NAME="${resolved_db_name}"
  PRIMARY_DB_UNIQUE_NAME="${resolved_db_unique_name}"
  PRIMARY_IS_RAC="${cluster_database}"
  print_message "Resolved PRIMARY_DB_NAME=${PRIMARY_DB_NAME} db_unique_name=${PRIMARY_DB_UNIQUE_NAME} cluster_database=${PRIMARY_IS_RAC}"
}

# Function to execute the remote truecache service creation file on the primary database
function executeRemoteTCSvcFile {

  local file_name
  local sql_file
  local connect_str
  local job_name
  local tc_connect_str
  local tc_service_name
  local association_output
  local condensed_output
  local scheduler_script_path_sql
  local primary_db_name_sql
  local primary_db_unique_name_sql
  local primary_is_rac_sql
  local password_source_sql
  local primary_service_sql
  local truecache_service_sql
  local primary_pdb_sql
  local tc_connect_str_sql
  local scheduler_credential_name_sql
  local scheduler_credential_stmt
  local scheduler_use_current_session_sql

  file_name=$1
  sql_file=$2
  # Submit the scheduler job through the primary CDB connect string. The
  # helper script on the primary host is responsible for creating and starting
  # the primary PDB service if it does not exist yet, so we must not require
  # PRIMARY_DB_APP_SVC to be listener-connectable before the helper runs.
  connect_str=${PRIMARY_DB_CONNECT_STR}
  job_name="bjob$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 7 | head -n 1)$time_stamp"
  HOST_NAME=${ORACLE_HOSTNAME:-$(hostname)}
  resolveTrueCacheCallbackServiceName
  tc_service_name="${TRUE_CACHE_CALLBACK_SERVICE_NAME}"
  tc_connect_str="$HOST_NAME:1521/${tc_service_name}"
  scheduler_script_path_sql=$(sqlEscapeLiteral "${PRIMARY_TC_SERVICE_SCRIPT_PATH}")
  primary_service_sql=$(sqlEscapeLiteral "${PRIMARY_DB_APP_SVC}")
  truecache_service_sql=$(sqlEscapeLiteral "${TRUE_CACHE_DB_APP_SVC}")
  primary_pdb_sql=$(sqlEscapeLiteral "${PRIMARY_PDB_NAME}")
  tc_connect_str_sql=$(sqlEscapeLiteral "${tc_connect_str}")
  primary_db_name_sql=$(sqlEscapeLiteral "${PRIMARY_DB_NAME}")
  primary_db_unique_name_sql=$(sqlEscapeLiteral "${PRIMARY_DB_UNIQUE_NAME}")
  primary_is_rac_sql=$(sqlEscapeLiteral "${PRIMARY_IS_RAC}")
  scheduler_credential_name_sql=$(sqlEscapeLiteral "${PRIMARY_TC_SERVICE_CREDENTIAL_NAME}")
  scheduler_credential_stmt=""
  if [ -n "${PRIMARY_TC_SERVICE_CREDENTIAL_NAME}" ]; then
    scheduler_credential_stmt="dbms_scheduler.set_attribute(name => '${job_name}', attribute => 'credential_name', value => '${scheduler_credential_name_sql}');"
  fi
  scheduler_use_current_session_sql="TRUE"
  if [ "${PRIMARY_IS_RAC}" = "true" ] || [ "${PRIMARY_IS_RAC}" = "TRUE" ]; then
    scheduler_use_current_session_sql="FALSE"
  fi
  if [ -n "${PRIMARY_TC_SERVICE_WALLET_PATH:-}" ]; then
    password_source_sql=$(sqlEscapeLiteral "WALLET_PATH:${PRIMARY_TC_SERVICE_WALLET_PATH}")
  elif [ -n "${ORACLE_PWD:-}" ]; then
    password_source_sql=$(sqlEscapeLiteral "B64:$(printf '%s' "${ORACLE_PWD}" | base64 -w0)")
  else
    password_source_sql=$(sqlEscapeLiteral "NO_PASSWORD")
  fi

  #### Execute the TCSvc-Remote file
  local sproc3="begin
          dbms_scheduler.create_job (job_name    => '${job_name}',
              job_type    => 'executable',
              job_action  => '${scheduler_script_path_sql}',
              number_of_arguments => 8,
              auto_drop   => TRUE);
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 1, argument_value => '${primary_service_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 2, argument_value => '${truecache_service_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 3, argument_value => '${primary_pdb_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 4, argument_value => '${tc_connect_str_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 5, argument_value => '${primary_db_name_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 6, argument_value => '${primary_db_unique_name_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 7, argument_value => '${primary_is_rac_sql}');
          dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 8, argument_value => '${password_source_sql}');
          ${scheduler_credential_stmt}
          dbms_scheduler.run_job(job_name => '${job_name}',USE_CURRENT_SESSION => ${scheduler_use_current_session_sql});
          end;
          /
  "

  print_message "Executing primary-host True Cache registration script ${PRIMARY_TC_SERVICE_SCRIPT_PATH} via DBMS_SCHEDULER on the primary database machine"
  echo "${sproc3}" > $sql_file
  output=$(getSQLOUTPUT "NULL" "${connect_str}" "sqlScript" "${sql_file}")
  if [ -n "$(echo "${output}" | xargs)" ]; then
    condensed_output=$(echo "${output}" | xargs)
    association_output=$(getPrimaryTrueCacheAssociation)
    if echo "${output}" | grep -q "ORA-27369" && [ "${association_output}" == "${TRUE_CACHE_DB_APP_SVC}" ]; then
      print_message "Primary-side service association completed despite scheduler noise. Deferring final validation to the post-job association check."
    elif echo "${output}" | grep -q "ORA-27369"; then
      DEFERRED_PRIMARY_SCHEDULER_WARNING="Primary DBMS_SCHEDULER executable job returned ORA-27369 before association was observable. Continuing to final verification because the primary-side registration can still finish asynchronously. Output: ${condensed_output}"
    else
      print_message "Received Output: $output"
    fi
  fi

  delFile "${sql_file}"
}

function getPrimaryPDBSQLOUTPUT {
  local sql_query=$1
  getSQLOUTPUT "ALTER SESSION SET CONTAINER=${PRIMARY_PDB_NAME};
${sql_query}" "${PRIMARY_DB_CONNECT_STR}"
}

function getPrimaryCDBSQLOUTPUT {
  local sql_query=$1
  getSQLOUTPUT "${sql_query}" "${PRIMARY_DB_CONNECT_STR}"
}

function getPrimaryTrueCacheAssociation {
  local association_output

  association_output=$(normalizeServiceName "$(getPrimaryCDBSQLOUTPUT "SELECT true_cache_service FROM v\$active_services WHERE upper(name)='${PRIMARY_DB_APP_SVC}';")")
  if [ -n "${association_output}" ]; then
    printf '%s' "${association_output}"
    return 0
  fi

  association_output=$(normalizeServiceName "$(getPrimaryPDBSQLOUTPUT "SELECT true_cache_service FROM ALL_SERVICES WHERE upper(name)='${PRIMARY_DB_APP_SVC}';")")
  if [ -n "${association_output}" ]; then
    printf '%s' "${association_output}"
  fi
}

function getPrimaryTrueCacheTransportStatus {
  local transport_output

  transport_output=$(printf '%s' "$(getPrimaryCDBSQLOUTPUT "SELECT 'DEST_ID=' || dest_id || ' STATUS=' || status || ' RECOVERY_MODE=' || recovery_mode FROM v\$archive_dest_status WHERE upper(db_unique_name)=upper('${TRUEDB_UNIQUE_NAME}') AND upper(status)='VALID' AND upper(recovery_mode) LIKE 'MANAGED REAL TIME APPLY%';")" | tr '\n' ' ' | xargs)
  transport_output=$(printf '%s' "${transport_output^^}")
  if [ -n "${transport_output}" ]; then
    printf '%s' "${transport_output}"
    return 0
  fi

  transport_output=$(printf '%s' "$(getPrimaryCDBSQLOUTPUT "SELECT 'DEST_ID=' || dest_id || ' STATUS=' || status || ' TARGET=' || target || ' DESTINATION=' || destination FROM v\$archive_dest WHERE upper(db_unique_name)=upper('${TRUEDB_UNIQUE_NAME}') AND upper(status)='VALID' AND upper(target)='STANDBY';")" | tr '\n' ' ' | xargs)
  transport_output=$(printf '%s' "${transport_output^^}")
  if [ -n "${transport_output}" ]; then
    printf '%s' "${transport_output}"
  fi
}

function printManualPrimaryRegistrationReminder {
  local host_name
  local tc_connect_str

  host_name=${ORACLE_HOSTNAME:-$(hostname)}
  resolveTrueCacheCallbackServiceName
  tc_connect_str="${host_name}:1521/${TRUE_CACHE_CALLBACK_SERVICE_NAME}"

  print_message "Configured True Cache service mapping PDB=${PRIMARY_PDB_NAME} PRIMARY_SERVICE=${PRIMARY_DB_APP_SVC} TRUECACHE_SERVICE=${TRUE_CACHE_DB_APP_SVC}"
  print_message "AUTO_TC_SVC_REGISTRATION=false, so primary-side service creation, startup, and True Cache association are not automated."
  print_message "Copy ${PRIMARY_TC_SERVICE_SCRIPT_PATH} to the primary host if it is not already present, make it executable for the Oracle software owner, and run it manually on the primary host."
  print_message "Manual primary-host command:"
  print_message "${PRIMARY_TC_SERVICE_SCRIPT_PATH} \"${PRIMARY_DB_APP_SVC}\" \"${TRUE_CACHE_DB_APP_SVC}\" \"${PRIMARY_PDB_NAME}\" \"${tc_connect_str}\" \"${PRIMARY_DB_NAME}\" \"${PRIMARY_DB_UNIQUE_NAME}\" \"${PRIMARY_IS_RAC}\" '<PRIMARY_SYS_PASSWORD_OR_WALLET_SOURCE>'"
}

function startTrueCacheSvcLocal {
  local connect_str
  local sql_query
  local output
  connect_str="/ as sysdba"

  if [ -z "${TRUE_CACHE_DB_APP_SVC}" ]; then
    return 0
  fi

  TRUE_CACHE_DB_APP_SVC=${TRUE_CACHE_DB_APP_SVC^^}
  waitForTrueCachePDBOpen || return 1

  sql_query="ALTER SESSION SET CONTAINER=${PRIMARY_PDB_NAME};
exec DBMS_SERVICE.START_SERVICE('${TRUE_CACHE_DB_APP_SVC}');
ALTER SYSTEM REGISTER;"
  output=$(getSQLOUTPUT "${sql_query}" "${connect_str}")
  print_message "True Cache local start service output: ${output}"
  waitForTrueCacheServiceActive || return 1
}

function ensureTrueCacheSvcExists {
  local service_name
  local service_exists
  local sql_query
  local timeout_seconds
  local elapsed
  local next_log_elapsed
  local association_output
  local transport_status

  if [ -z "${TRUE_CACHE_DB_APP_SVC}" ]; then
    return 0
  fi

  service_name=${TRUE_CACHE_DB_APP_SVC^^}
  sql_query="ALTER SESSION SET CONTAINER=${PRIMARY_PDB_NAME};
SELECT name FROM cdb_services WHERE upper(name)='${service_name}';"
  service_exists=$(normalizeServiceName "$(getSQLOUTPUT "${sql_query}" "/ as sysdba")")

  if [ "${service_exists}" == "${service_name}" ]; then
    print_message "True Cache service ${service_name} already exists in PDB ${PRIMARY_PDB_NAME}."
    return 0
  fi

  timeout_seconds=${TRUECACHE_SERVICE_START_TIMEOUT_SECONDS}
  elapsed=0
  next_log_elapsed=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    service_exists=$(normalizeServiceName "$(getSQLOUTPUT "ALTER SESSION SET CONTAINER=${PRIMARY_PDB_NAME};
SELECT name FROM cdb_services WHERE upper(name)='${service_name}';" "/ as sysdba")")

    if [ "${service_exists}" == "${service_name}" ]; then
      print_message "True Cache service ${service_name} is now present in PDB ${PRIMARY_PDB_NAME}."
      return 0
    fi

    if [ "${elapsed}" -ge "${next_log_elapsed}" ]; then
      association_output=$(getPrimaryTrueCacheAssociation)
      transport_status=$(getPrimaryTrueCacheTransportStatus)
      print_message "Waiting for True Cache service ${service_name} to become visible in PDB ${PRIMARY_PDB_NAME}. association=[${association_output}] transport=[${transport_status}] elapsed=${elapsed}s"
      next_log_elapsed=$((elapsed + 15))
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  association_output=$(getPrimaryTrueCacheAssociation)
  transport_status=$(getPrimaryTrueCacheTransportStatus)
  print_message "True Cache service ${service_name} did not become visible in PDB ${PRIMARY_PDB_NAME}. final_association=[${association_output}] transport=[${transport_status}]"
  return 1
}

function checkTrueCacheSvcLocal {
  local active_query
  local local_connect_str
  local active_output
  TRUE_CACHE_DB_APP_SVC=${TRUE_CACHE_DB_APP_SVC^^}
  active_query="SELECT name FROM v\$active_services WHERE upper(name)='${TRUE_CACHE_DB_APP_SVC}';"
  local_connect_str="/ as sysdba"
  active_output=$(normalizeServiceName "$(getSQLOUTPUT "${active_query}" "${local_connect_str}")")

  if [ "${active_output}" == "${TRUE_CACHE_DB_APP_SVC}" ]; then
    print_message "True Cache Service ${TRUE_CACHE_DB_APP_SVC} is active on the True Cache database."
  else
    print_message "True Cache Service ${TRUE_CACHE_DB_APP_SVC} is not active on the True Cache database."
  fi
}

# Start the local True Cache app service after the primary-side association
# step has had a chance to create/configure it.
function startTrueCacheSvc {
  local truecache_connect_str
  truecache_connect_str="/ as sysdba"

  if [ ! -z "${TRUE_CACHE_DB_APP_SVC}" ]; then
    TRUE_CACHE_DB_APP_SVC=${TRUE_CACHE_DB_APP_SVC^^}
    local sql_query
    local output
    waitForTrueCachePDBOpen || return 1
    ensureTrueCacheSvcExists || return 1
    if isTrueCacheServiceActive; then
      print_message "True Cache service ${TRUE_CACHE_DB_APP_SVC} is already active locally. Skipping START_SERVICE."
      return 0
    fi
    sqlquery2="ALTER SESSION SET CONTAINER=${PRIMARY_PDB_NAME};
exec DBMS_SERVICE.START_SERVICE('${TRUE_CACHE_DB_APP_SVC}');
ALTER SYSTEM REGISTER;"
    output=$( getSQLOUTPUT "${sqlquery2}" "${truecache_connect_str}")
    output=$(printf '%s' "${output}" | xargs)
    print_message "True Cache start service output: ${output}"
    if echo "${output}" | grep -q "ORA-"; then
      if isTrueCacheServiceActive; then
        print_message "True Cache service ${TRUE_CACHE_DB_APP_SVC} is active despite START_SERVICE output. Continuing."
        return 0
      fi
      print_message "True Cache local service start failed for ${TRUE_CACHE_DB_APP_SVC}."
      return 1
    fi
    waitForTrueCacheServiceActive || return 1
  fi
}

# Function to create the True Cache service
# shellcheck disable=SC2120
function createTCSvc {
  if [ ! -z "${TRUE_CACHE_DB_APP_SVC}" ]; then
    TRUE_CACHE_DB_APP_SVC=${TRUE_CACHE_DB_APP_SVC^^}
    local association_output
    association_output=$(getPrimaryTrueCacheAssociation)
    if [ "${association_output}" == "${TRUE_CACHE_DB_APP_SVC}" ] && isTrueCacheServiceActive; then
      print_message "Primary service ${PRIMARY_DB_APP_SVC} is already associated with True Cache service ${TRUE_CACHE_DB_APP_SVC}, and the True Cache service is active locally. Skipping remote configuration."
      return 0
    fi
    if [ "${association_output}" == "${TRUE_CACHE_DB_APP_SVC}" ]; then
      print_message "Primary service ${PRIMARY_DB_APP_SVC} is already associated with True Cache service ${TRUE_CACHE_DB_APP_SVC}. Skipping remote DBCA and finishing the local True Cache service setup."
      return 0
    fi
    executeRemoteTCSvcFile "${PRIMARY_TC_SERVICE_SCRIPT_PATH}" "${TMP_LOC}/tc_svc_sqlquery.sql"
    if ! waitForPrimaryTrueCacheAssociation; then
      print_message "Primary association metadata was not yet visible after the wait budget. Proceeding to local service startup and final end-to-end verification."
    fi
  fi
}

# Function to check the True Cache service
function checkTCSvc {
  TRUE_CACHE_DB_APP_SVC=${TRUE_CACHE_DB_APP_SVC^^}
  PRIMARY_DB_APP_SVC=${PRIMARY_DB_APP_SVC^^}
  local association_query
  local active_query
  local local_connect_str
  local association_output
  local active_output
  local transport_status
  association_query="SELECT true_cache_service FROM ALL_SERVICES WHERE upper(name)='${PRIMARY_DB_APP_SVC}';"
  active_query="SELECT name FROM v\$active_services WHERE upper(name)='${TRUE_CACHE_DB_APP_SVC}';"
  local_connect_str="/ as sysdba"
  association_output=$(normalizeServiceName "$(getPrimaryPDBSQLOUTPUT "${association_query}")")
  active_output=$(normalizeServiceName "$(getSQLOUTPUT "${active_query}" "${local_connect_str}")")
  transport_status=$(getPrimaryTrueCacheTransportStatus)

  if [ "${association_output}" == "${TRUE_CACHE_DB_APP_SVC}" ] && [ "${active_output}" == "${TRUE_CACHE_DB_APP_SVC}" ]; then
    if [ -n "${DEFERRED_PRIMARY_SCHEDULER_WARNING}" ]; then
      print_message "Primary-side registration completed despite earlier scheduler noise."
      DEFERRED_PRIMARY_SCHEDULER_WARNING=""
    fi
    print_message "True Cache Service ${TRUE_CACHE_DB_APP_SVC} is associated with primary service ${PRIMARY_DB_APP_SVC} and active on True Cache. final_association=[${association_output}] final_active=[${active_output}]"
    return 0
  elif [ -z "${association_output}" ] && [ "${active_output}" == "${TRUE_CACHE_DB_APP_SVC}" ] && [ -n "${transport_status}" ]; then
    if [ -n "${DEFERRED_PRIMARY_SCHEDULER_WARNING}" ]; then
      print_message "${DEFERRED_PRIMARY_SCHEDULER_WARNING}"
      DEFERRED_PRIMARY_SCHEDULER_WARNING=""
      print_message "Primary-side service registration did not complete. True Cache transport is active, but the primary association metadata is still empty. final_association=[${association_output}] final_active=[${active_output}] transport=[${transport_status}]"
      return 1
    fi
    print_message "True Cache transport is active for ${TRUEDB_UNIQUE_NAME} even though service metadata is still empty. final_association=[${association_output}] final_active=[${active_output}] transport=[${transport_status}]"
    return 0
  else
    if [ -n "${DEFERRED_PRIMARY_SCHEDULER_WARNING}" ]; then
      print_message "${DEFERRED_PRIMARY_SCHEDULER_WARNING}"
      DEFERRED_PRIMARY_SCHEDULER_WARNING=""
    fi
    print_message "True Cache Service check failed. association=[${association_output}] active=[${active_output}] expected=[${TRUE_CACHE_DB_APP_SVC}]"
    return 1
  fi
}

# Check if the given pdb exists on the primary database
function checkPDBExists {
  local pdb_name
  local sql_query
  local connect_str
  local output
  pdb_name=$1
  sql_query="SELECT open_mode FROM v\$pdbs WHERE name='${pdb_name}';"
  connect_str="${PRIMARY_DB_CONNECT_STR}"

  output=$( getSQLOUTPUT "${sql_query}" "${connect_str}")

  echo "OPEN_MODE output=[$output]"

  if [ "${output}" == "READ WRITE" ]; then
      pdbExists="1"
  else
      pdbExists="0"
  fi
}

#####################################
#####  MAIN #########################
#####################################

AUTO_TC_SVC_REGISTRATION=${AUTO_TC_SVC_REGISTRATION:-false}
if [[ "${TRUE_CACHE}" == "true" ]]; then
  PRIMARY_DB_HOST=$(echo "$PRIMARY_DB_CONN_STR" | cut -d ':' -f1)
  PRIMARY_DB_PORT=$(echo "$PRIMARY_DB_CONN_STR" | cut -d ":" -f2 | cut -d '/' -f1)

  ORACLE_PWD=$($ORACLE_BASE/$DECRYPT_PWD_FILE || true)
  if [ -n "${ORACLE_PWD}" ]; then
    resolvePrimaryDbName
  elif hasTrueCacheDBCredentialsWallet; then
    print_message "ORACLE_PWD is not set. Using dbCredentialsWallet for primary SQL connectivity."
    resolvePrimaryDbName
  else
    if [[ "${AUTO_TC_SVC_REGISTRATION}" == "true" ]]; then
      print_message "AUTO_TC_SVC_REGISTRATION=true requested, but neither ORACLE_PWD nor dbCredentialsWallet is available. Falling back to the manual helper reminder."
      AUTO_TC_SVC_REGISTRATION=false
    fi
    if [ -n "${PRIMARY_DB_NAME:-}" ]; then
      print_message "Using caller-provided PRIMARY_DB_NAME=${PRIMARY_DB_NAME} for manual primary-side registration guidance."
    else
      PRIMARY_DB_NAME="${PRIMARY_DB_CONN_STR#*/}"
      print_message "ORACLE_PWD is not set, so keeping PRIMARY_DB_NAME=${PRIMARY_DB_NAME}. Set PRIMARY_DB_NAME or primarySource.dbName explicitly when the primary service name differs from the primary CDB DB_NAME."
    fi
  fi
  PDB_TC_SVCS_STR=`echo ${PDB_TC_SVCS} | sed -e 's/.*?=\(.*\)/\1/g'`
  print_message "PDB_TC_SVCS_STR=${PDB_TC_SVCS_STR}"
  IFS=';' read  -a PDB_TC_VALUES <<< "${PDB_TC_SVCS_STR}"
  print_message "# of PDB_TC_VALUES=${#PDB_TC_VALUES[@]}"
  for PDB_TC_VALUE in "${PDB_TC_VALUES[@]}"
  do
    IFS=':' read PDB_NAME PRIMARY_SVC_NAME TC_SVC_NAME <<< "${PDB_TC_VALUE}"
    if [ "${PDB_NAME}" == "" -o "${PRIMARY_SVC_NAME}" == "" -o "${TC_SVC_NAME}" == "" ]; then
      error_exit "Bad service mapping [${PRIMARY_SVC_NAME}:${TC_SVC_NAME}] for db [${PDB_NAME}]. Ignoring"
      continue
    fi
      export PRIMARY_DB_APP_SVC=${PRIMARY_SVC_NAME}
      export TRUE_CACHE_DB_APP_SVC=${TC_SVC_NAME}
      export PRIMARY_PDB_NAME=${PDB_NAME}

      if [[ "${AUTO_TC_SVC_REGISTRATION}" == "true" ]]; then
        print_message "setting connect str for pdb ${PRIMARY_PDB_NAME}"
        setConnectStr
        print_message "validate if the ${PDB_NAME} pdb exists"
        checkPDBExists "${PDB_NAME}"
        if [ "${pdbExists}" == "0" ]; then
              echo "The PDB ${PDB_NAME} does not exist. Ignoring"
              continue
        fi
        waitForTrueCacheListenerConnectable || return 1
        print_message "running primary-host registration helper for PRIMARY_SERVICE=${PRIMARY_DB_APP_SVC} TRUECACHE_SERVICE=${TRUE_CACHE_DB_APP_SVC}"
        createTCSvc
        startTrueCacheSvc
        checkTCSvc || return 1
      else
        printManualPrimaryRegistrationReminder
      fi
  done
fi
