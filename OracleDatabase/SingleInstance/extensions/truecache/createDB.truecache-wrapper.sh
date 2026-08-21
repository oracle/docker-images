#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Prepare a bind-all listener for True Cache DBCA startup, then
#              delegate to the base createDB.sh implementation.
#

print_message() {
  local now
  now=$(date +"%m-%d-%Y %T %Z")
  echo "${now} : createDB.truecache-wrapper.sh : ${1:-Unknown message}"
}

has_true_cache_db_credentials_wallet() {
  [ -n "${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR:-}" ] && [ -f "${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR}/ewallet.p12" ]
}

using_true_cache_wallet_only_dbca_auth() {
  [ -z "${ORACLE_PWD:-}" ] && [ -n "${WALLET_DIR:-}" ] && [ -f "${WALLET_DIR}/ewallet.p12" ]
}

ensure_true_cache_primary_wallet_tns_admin() {
  local tns_admin_dir

  if ! has_true_cache_db_credentials_wallet; then
    return 1
  fi

  if [ -n "${TRUECACHE_PRIMARY_WALLET_TNS_ADMIN:-}" ] && [ -f "${TRUECACHE_PRIMARY_WALLET_TNS_ADMIN}/sqlnet.ora" ]; then
    export TNS_ADMIN="${TRUECACHE_PRIMARY_WALLET_TNS_ADMIN}"
    return 0
  fi

  tns_admin_dir="${TMP_LOC:-/var/tmp}/truecache-primary-wallet-$$"
  mkdir -p "${tns_admin_dir}" || return 1
  cat > "${tns_admin_dir}/sqlnet.ora" <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = ${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR})))
SQLNET.WALLET_OVERRIDE = TRUE
NAMES.DIRECTORY_PATH = (EZCONNECT, TNSNAMES, HOSTNAME)
SQLNET.EXPIRE_TIME=3
EOF
  export TRUECACHE_PRIMARY_WALLET_TNS_ADMIN="${tns_admin_dir}"
  export TNS_ADMIN="${tns_admin_dir}"
  print_message "Using wallet-backed TNS_ADMIN=${TNS_ADMIN} for primary metadata lookup."
}

build_true_cache_primary_connect_str() {
  local connect_target=$1

  if [ -n "${ORACLE_PWD:-}" ]; then
    printf 'sys/%s@%s as sysdba\n' "${ORACLE_PWD}" "${connect_target}"
    return 0
  fi

  if ensure_true_cache_primary_wallet_tns_admin; then
    printf '/@%s as sysdba\n' "${connect_target}"
    return 0
  fi

  return 1
}

resolve_true_cache_primary_db_name() {
  local resolved_db_name
  local connect_str

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if [ -n "${PRIMARY_DB_CONN_STR:-}" ] && connect_str=$(build_true_cache_primary_connect_str "${PRIMARY_DB_CONN_STR}"); then
    resolved_db_name=$(sqlplus -s "${connect_str}" <<'EOF'
set heading off feedback off verify off echo off pagesize 0
select name from v$database;
exit
EOF
)
    resolved_db_name=$(echo "${resolved_db_name}" | xargs)
    if [ -n "${resolved_db_name}" ]; then
      if [ -n "${PRIMARY_DB_NAME:-}" ]; then
        print_message "Using caller-provided PRIMARY_DB_NAME=${PRIMARY_DB_NAME}."
        if [ "${PRIMARY_DB_NAME^^}" != "${resolved_db_name^^}" ]; then
          print_message "PRIMARY_DB_NAME ${PRIMARY_DB_NAME} does not match primary metadata db_name=${resolved_db_name}. Using db_name ${resolved_db_name} for DBCA sourceDB."
        fi
      fi
      export PRIMARY_DB_NAME="${resolved_db_name}"
      print_message "Resolved PRIMARY_DB_NAME=${PRIMARY_DB_NAME} from primary metadata for True Cache DBCA."
      return 0
    fi
  fi

  if [ -n "${PRIMARY_DB_NAME:-}" ]; then
    print_message "Keeping caller-provided PRIMARY_DB_NAME=${PRIMARY_DB_NAME} because primary metadata lookup was unavailable."
    return 0
  fi

  export PRIMARY_DB_NAME="${PRIMARY_DB_CONN_STR#*/}"
  print_message "Falling back to PRIMARY_DB_NAME=${PRIMARY_DB_NAME} from PRIMARY_DB_CONN_STR. Set PRIMARY_DB_NAME or primarySource.dbName explicitly when the primary service name differs from the primary CDB DB_NAME."
}

prepare_true_cache_dbca_args() {
  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  resolve_true_cache_primary_db_name || return 1

  unset TRUECACHE_DBCA_INIT_PARAMS
  if [ -n "${INIT_PROCESSES:-}" ]; then
    export TRUECACHE_DBCA_INIT_PARAMS="processes=${INIT_PROCESSES}"
    print_message "Routing INIT_PROCESSES through the True Cache DBCA shim."
  fi
}

resolve_true_cache_callback_service() {
  local primary_service callback_domain

  if [ -n "${TRUE_CACHE_CALLBACK_SERVICE:-}" ]; then
    printf '%s\n' "${TRUE_CACHE_CALLBACK_SERVICE}"
    return 0
  fi

  primary_service="${PRIMARY_DB_CONN_STR#*/}"
  if [ "${primary_service}" != "${PRIMARY_DB_CONN_STR}" ] && [[ "${primary_service}" == *.* ]]; then
    callback_domain="${primary_service#*.}"
    printf '%s.%s\n' "${TRUEDB_UNIQUE_NAME}" "${callback_domain}"
    return 0
  fi

  printf '%s\n' "${TRUEDB_UNIQUE_NAME}"
}

start_true_cache_dbca_listener() {
  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if "${ORACLE_HOME}/bin/lsnrctl" status LISTENER >/dev/null 2>&1; then
    export TRUECACHE_LISTENER_WAS_RUNNING=true
    print_message "Listener LISTENER already running before DBCA startup."
    return 0
  fi

  export TRUECACHE_LISTENER_WAS_RUNNING=false
  print_message "Starting listener LISTENER before DBCA startup to warm the external callback path."
  "${ORACLE_HOME}/bin/lsnrctl" start LISTENER >/dev/null 2>&1 || return 1
  "${ORACLE_HOME}/bin/lsnrctl" status LISTENER >/dev/null 2>&1 || return 1
}

listener_port_is_reachable() {
  timeout 2 bash -lc "echo > /dev/tcp/127.0.0.1/1521" >/dev/null 2>&1
}

stop_true_cache_dbca_listener_for_dbca() {
  local elapsed
  local timeout_seconds

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if [ "${TRUECACHE_LISTENER_WAS_RUNNING:-false}" = "true" ]; then
    print_message "Listener LISTENER was already running before warm-up; leaving it untouched for DBCA."
    return 0
  fi

  if ! "${ORACLE_HOME}/bin/lsnrctl" status LISTENER >/dev/null 2>&1; then
    return 0
  fi

  print_message "Stopping temporary listener LISTENER before DBCA so DBCA can bind the callback listener on 1521."
  "${ORACLE_HOME}/bin/lsnrctl" stop LISTENER >/dev/null 2>&1 || return 1

  timeout_seconds="${TRUECACHE_LISTENER_RELEASE_TIMEOUT_SECONDS:-30}"
  if ! [[ "${timeout_seconds}" =~ ^[0-9]+$ ]] || [ "${timeout_seconds}" -le 0 ]; then
    timeout_seconds=30
  fi

  elapsed=0
  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    if ! listener_port_is_reachable; then
      print_message "Listener port 1521 is free for DBCA."
      return 0
    fi

    sleep 1
    elapsed=$((elapsed + 1))
  done

  print_message "Timed out waiting for listener port 1521 to become free for DBCA."
  return 1
}

wait_for_true_cache_external_callback() {
  local timeout_seconds elapsed callback_service callback_host connect_target output

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if [ -z "${ORACLE_HOSTNAME:-}" ] || [ -z "${TRUEDB_UNIQUE_NAME:-}" ]; then
    print_message "Skipping external callback wait because ORACLE_HOSTNAME or TRUEDB_UNIQUE_NAME is not set."
    return 0
  fi

  timeout_seconds="${TRUECACHE_CALLBACK_READY_TIMEOUT_SECONDS:-120}"
  if ! [[ "${timeout_seconds}" =~ ^[0-9]+$ ]] || [ "${timeout_seconds}" -le 0 ]; then
    timeout_seconds=120
  fi

  callback_service=$(resolve_true_cache_callback_service)
  callback_host="${TRUECACHE_CALLBACK_HOST:-${ORACLE_HOSTNAME}}"
  connect_target="//${callback_host}:1521/${callback_service}"
  elapsed=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    output=$("${ORACLE_HOME}/bin/tnsping" "${connect_target}" 2>/dev/null || true)
    output=$(printf '%s\n' "${output}" | xargs)

    if printf '%s\n' "${output}" | grep -q "OK ("; then
      print_message "External callback target ${connect_target} is connectable."
      return 0
    fi

    if [ "${elapsed}" -eq 0 ]; then
      print_message "Waiting for external callback target ${connect_target} to become connectable."
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  print_message "Timed out waiting for external callback target ${connect_target} to become connectable."
  return 1
}

disable_local_dbca_credential_wallet_for_true_cache() {
  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if [ -n "${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR:-}" ] && [ -f "${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR}/ewallet.p12" ]; then
    export WALLET_DIR="${TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR}"
    print_message "Using True Cache DB credentials wallet from ${WALLET_DIR} for DBCA primary authentication."
    return 0
  fi

  if [ -n "${WALLET_DIR:-}" ] && [ -f "${WALLET_DIR}/ewallet.p12" ]; then
    print_message "Using caller-provided WALLET_DIR=${WALLET_DIR} for True Cache DBCA primary authentication."
    return 0
  fi

  print_message "No True Cache DB credentials wallet was found. DBCA will fall back to ORACLE_PWD if it is set."
}

ensure_true_cache_wallet_root_bridge() {
  local dbconfig_dir sid_wallet_dir target_unique_name wallet_root_dir wallet_root_link current_target

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  dbconfig_dir="${ORACLE_BASE:-/opt/oracle}/oradata/dbconfig/${ORACLE_SID}"
  sid_wallet_dir="${dbconfig_dir}/tde"
  target_unique_name="${TRUEDB_UNIQUE_NAME:-${ORACLE_SID}}"
  wallet_root_dir="${ORACLE_BASE:-/opt/oracle}/admin/${target_unique_name}/wallet_root"
  wallet_root_link="${wallet_root_dir}/tde"

  if [ ! -f "${sid_wallet_dir}/ewallet.p12" ]; then
    print_message "Skipping True Cache wallet-root bridge because ${sid_wallet_dir}/ewallet.p12 is not present."
    return 0
  fi

  mkdir -p "${wallet_root_dir}" || return 1

  if [ -L "${wallet_root_link}" ]; then
    current_target=$(readlink "${wallet_root_link}" || true)
    if [ "${current_target}" = "${sid_wallet_dir}" ]; then
      print_message "True Cache wallet-root bridge already points to ${sid_wallet_dir}."
      return 0
    fi
    rm -f "${wallet_root_link}" || return 1
  elif [ -e "${wallet_root_link}" ]; then
    if find "${wallet_root_link}" -maxdepth 2 -type f \( -name "cwallet.sso" -o -name "ewallet.p12" \) | grep -q .; then
      print_message "Leaving existing True Cache wallet-root content in ${wallet_root_link}."
      return 0
    fi
    rm -rf "${wallet_root_link}" || return 1
  fi

  ln -s "${sid_wallet_dir}" "${wallet_root_link}" || return 1
  print_message "Linked True Cache wallet_root ${wallet_root_link} -> ${sid_wallet_dir}."
}

seed_true_cache_tde_wallet_from_blob() {
  local dbconfig_dir sid_wallet_dir current_target

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if [ -z "${TRUE_CACHE_BLOB:-}" ] || [ ! -f "${TRUE_CACHE_BLOB}" ]; then
    print_message "Skipping True Cache TDE wallet seed because TRUE_CACHE_BLOB is not present."
    return 0
  fi

  if [ -z "${TDE_WALLET_PWD:-}" ]; then
    print_message "Skipping True Cache TDE wallet seed because TDE_WALLET_PWD is not set."
    return 0
  fi

  dbconfig_dir="${ORACLE_BASE:-/opt/oracle}/oradata/dbconfig/${ORACLE_SID}"
  sid_wallet_dir="${dbconfig_dir}/tde"

  if [ -L "${sid_wallet_dir}" ]; then
    current_target=$(readlink "${sid_wallet_dir}" || true)
    if [ "${current_target}" = "${dbconfig_dir}/.wallet" ]; then
      rm -f "${sid_wallet_dir}" || return 1
    fi
  fi

  mkdir -p "${sid_wallet_dir}" || return 1
  tar -xzf "${TRUE_CACHE_BLOB}" -C "${sid_wallet_dir}" ewallet.p12 || return 1
  print_message "Seeded True Cache TDE wallet from ${TRUE_CACHE_BLOB} into ${sid_wallet_dir}."

  "${ORACLE_HOME}/bin/orapki" wallet create -wallet "${sid_wallet_dir}" -auto_login >/dev/null <<EOF
${TDE_WALLET_PWD}
${TDE_WALLET_PWD}
EOF
  print_message "Created True Cache auto-login wallet at ${sid_wallet_dir}."
}

prepare_true_cache_dbca_listener() {
  local network_admin listener_file callback_service_fqdn

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  network_admin="${ORACLE_HOME}/network/admin"
  listener_file="${network_admin}/listener.ora"
  callback_service_fqdn=$(resolve_true_cache_callback_service)

  mkdir -p "${network_admin}" || return 1

  cat > "${listener_file}" <<EOF
LISTENER =
(DESCRIPTION_LIST =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1))
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  )
)

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${TRUEDB_UNIQUE_NAME})
      (SID_NAME = ${ORACLE_SID})
      (ORACLE_HOME = ${ORACLE_HOME})
    )
EOF

  if [ -n "${callback_service_fqdn}" ] && [ "${callback_service_fqdn}" != "${TRUEDB_UNIQUE_NAME}" ]; then
    cat >> "${listener_file}" <<EOF
    (SID_DESC =
      (GLOBAL_DBNAME = ${callback_service_fqdn})
      (SID_NAME = ${ORACLE_SID})
      (ORACLE_HOME = ${ORACLE_HOME})
    )
EOF
  fi

  cat >> "${listener_file}" <<EOF
  )

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
EOF
}

pin_primary_connect_string_for_rac() {
  local connect_str metadata_output listener_output cluster_database local_host local_port service_name resolved_db_name resolved_db_unique_name instance_name instance_connect_str

  if [ "${TRUE_CACHE}" != "true" ] || [ -z "${PRIMARY_DB_CONN_STR:-}" ]; then
    return 0
  fi

  if ! connect_str=$(build_true_cache_primary_connect_str "${PRIMARY_DB_CONN_STR}"); then
    print_message "Skipping RAC primary metadata pinning because neither ORACLE_PWD nor dbCredentialsWallet is available. Keep PRIMARY_DB_NAME or primarySource.dbName aligned with the primary CDB DB_NAME."
    return 0
  fi

  service_name="${PRIMARY_DB_CONN_STR#*/}"
  if [ -z "${service_name}" ] || [ "${service_name}" = "${PRIMARY_DB_CONN_STR}" ]; then
    return 0
  fi

  metadata_output=$("${ORACLE_HOME}/bin/sqlplus" -s "${connect_str}" <<'EOF'
whenever sqlerror exit failure
set heading off feedback off verify off echo off pages 0
select db.name
       || '|'
       || db.db_unique_name
       || '|'
       || lower(c.value)
  from v$database db,
       v$parameter c
 where c.name = 'cluster_database'
exit
EOF
)
  metadata_output=$(printf '%s\n' "${metadata_output}" | awk -F'|' '
    /^[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*(true|false)[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print
      exit
    }
  ')

  if [ -z "${metadata_output}" ]; then
    return 0
  fi

  IFS='|' read -r resolved_db_name resolved_db_unique_name cluster_database <<EOF
${metadata_output}
EOF

  cluster_database=$(echo "${cluster_database}" | xargs)
  resolved_db_name=$(echo "${resolved_db_name}" | xargs)
  resolved_db_unique_name=$(echo "${resolved_db_unique_name}" | xargs)

  if [ -n "${resolved_db_name}" ] && [[ ! "${resolved_db_name}" =~ ^[[:alnum:]_$#]+$ ]]; then
    print_message "Ignoring malformed primary metadata db_name=${resolved_db_name} from ${PRIMARY_DB_CONN_STR}; keeping original connect string."
    return 0
  fi

  if [ -n "${resolved_db_name}" ] && [ "${PRIMARY_DB_NAME:-}" != "${resolved_db_name}" ]; then
    if [ -n "${PRIMARY_DB_NAME:-}" ]; then
      print_message "PRIMARY_DB_NAME ${PRIMARY_DB_NAME} does not match primary metadata db_name=${resolved_db_name} db_unique_name=${resolved_db_unique_name}. Using db_name ${resolved_db_name} for DBCA sourceDB."
    fi
    export PRIMARY_DB_NAME="${resolved_db_name}"
  fi

  if [ "${cluster_database}" != "true" ]; then
    return 0
  fi

  listener_output=$("${ORACLE_HOME}/bin/sqlplus" -s "${connect_str}" <<'EOF'
whenever sqlerror exit failure
set heading off feedback off verify off echo off pages 0
select primary_inst.instance_name
       || '|'
       || trim(nvl(regexp_substr(primary_inst.local_listener, 'HOST *= *([^)]*)', 1, 1, 'i', 1), primary_inst.host_name))
       || '|'
       || trim(nvl(regexp_substr(primary_inst.local_listener, 'PORT *= *([0-9]+)', 1, 1, 'i', 1), '1521'))
  from (
         select instance_name, host_name, local_listener
           from (
             select inst.inst_id,
                    inst.instance_name,
                    inst.host_name,
                    param.value as local_listener,
                    row_number() over (order by inst.inst_id) as rn
               from gv$instance inst
               left join gv$parameter param
                 on param.inst_id = inst.inst_id
                and param.name = 'local_listener'
           )
          where rn = 1
       ) primary_inst
exit
EOF
)
  listener_output=$(printf '%s\n' "${listener_output}" | awk -F'|' '
    /^[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*[0-9]+[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print
      exit
    }
  ')

  if [ -z "${listener_output}" ]; then
    return 0
  fi

  IFS='|' read -r instance_name local_host local_port <<EOF
${listener_output}
EOF

  instance_name=$(echo "${instance_name}" | xargs)
  local_host=$(echo "${local_host}" | xargs)
  local_port=$(echo "${local_port}" | xargs)

  if [ -z "${local_host}" ] || [ -z "${local_port}" ]; then
    return 0
  fi

  if [ -n "${instance_name}" ]; then
    instance_connect_str=$(build_true_cache_primary_connect_str "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${local_host})(PORT=${local_port}))(CONNECT_DATA=(SERVICE_NAME=${service_name})(INSTANCE_NAME=${instance_name})))") || {
      print_message "Unable to build instance-specific RAC metadata connect string for ${local_host}:${local_port}/${service_name}; keeping original connect string."
      return 0
    }
    if ! "${ORACLE_HOME}/bin/sqlplus" -s -L "${instance_connect_str}" <<'EOF' >/dev/null 2>&1
whenever sqlerror exit failure
select 1 from dual;
exit
EOF
    then
      print_message "Pinned RAC candidate ${local_host}:${local_port}/${service_name} did not support instance-specific connect for ${instance_name}; keeping original connect string."
      return 0
    fi
  fi

  export PRIMARY_DB_CONN_STR="${local_host}:${local_port}/${service_name}"
  print_message "Pinned RAC PRIMARY_DB_CONN_STR to ${PRIMARY_DB_CONN_STR} for DBCA create path."
}

install_true_cache_dbca_shim() {
  local shim_dir

  if [ "${TRUE_CACHE}" != "true" ]; then
    return 0
  fi

  if [ -z "${ORACLE_HOME:-}" ] || [ ! -x "${ORACLE_HOME}/bin/dbca" ]; then
    print_message "Unable to install True Cache DBCA shim because ${ORACLE_HOME:-unset}/bin/dbca is not executable."
    return 1
  fi

  shim_dir=$(mktemp -d "${TMPDIR:-/tmp}/truecache-dbca.XXXXXX") || return 1
  export TRUECACHE_DBCA_SHIM_DIR="${shim_dir}"
  export TRUECACHE_REAL_DBCA_PATH="${ORACLE_HOME}/bin/dbca"

  cat > "${TRUECACHE_DBCA_SHIM_DIR}/dbca" <<'EOF'
#!/bin/bash
set -euo pipefail

print_message() {
  local now
  now=$(date +"%m-%d-%Y %T %Z")
  echo "${now} : createDB.truecache-wrapper.sh : ${1:-Unknown message}"
}

has_arg() {
  local key=$1
  shift
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "${key}" ]; then
      return 0
    fi
    shift
  done
  return 1
}

using_true_cache_wallet_only_dbca_auth() {
  [ -z "${ORACLE_PWD:-}" ] && [ -n "${WALLET_DIR:-}" ] && [ -f "${WALLET_DIR}/ewallet.p12" ]
}

get_arg_value() {
  local key=$1
  shift
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "${key}" ] && [ "$#" -ge 2 ]; then
      printf '%s\n' "$2"
      return 0
    fi
    shift
  done
  return 1
}

normalize_true_cache_dbca_stdin_for_wallet_auth() {
  local stdin_file=$1
  local normalized_file
  shift

  if [ "${TRUE_CACHE:-}" != "true" ]; then
    return 0
  fi

  if [ "${TDE_ENABLED:-false}" = "true" ] && [ -n "${ORACLE_PWD:-}" ] && has_arg "-sourceTdeWalletPassword" "$@"; then
    if [ -s "${stdin_file}" ] && [ "$(sed -n '$p' "${stdin_file}")" = "${TDE_WALLET_PWD:-}" ]; then
      normalized_file="${stdin_file}.normalized"
      sed '$d' "${stdin_file}" > "${normalized_file}" || return 1
      mv "${normalized_file}" "${stdin_file}" || return 1
      print_message "Removed legacy TDE wallet password stdin line because -sourceTdeWalletPassword is enabled."
    fi
  fi

  if ! using_true_cache_wallet_only_dbca_auth; then
    return 0
  fi

  if [ "${TDE_ENABLED:-false}" != "true" ] || [ ! -s "${stdin_file}" ] || [ -n "$(sed -n '1p' "${stdin_file}")" ] || [ -z "$(sed -n '2p' "${stdin_file}")" ]; then
    return 0
  fi

  normalized_file="${stdin_file}.normalized"
  sed '1{/^$/d;}' "${stdin_file}" > "${normalized_file}" || return 1
  mv "${normalized_file}" "${stdin_file}" || return 1
  print_message "Removed legacy empty remote SYS password line from True Cache DBCA stdin because wallet-only auth is enabled."
}

resolve_alert_log() {
  local sid=$1
  local log_file

  log_file=$(find "${ORACLE_BASE:-/opt/oracle}/diag/rdbms" -name "alert_${sid}.log" 2>/dev/null | head -n 1 || true)
  printf '%s\n' "${log_file}"
}

is_true_cache_flashback_failure() {
  local db_unique_name sid alert_log dbca_log

  db_unique_name=$(get_arg_value "-dbUniqueName" "$@" || true)
  sid=$(get_arg_value "-sid" "$@" || true)
  sid=${sid:-${ORACLE_SID:-}}

  if [ -n "${db_unique_name}" ] && [ -f "${ORACLE_BASE:-/opt/oracle}/cfgtoollogs/dbca/${db_unique_name}/${db_unique_name}.log" ]; then
    dbca_log="${ORACLE_BASE:-/opt/oracle}/cfgtoollogs/dbca/${db_unique_name}/${db_unique_name}.log"
  elif [ -n "${sid}" ] && [ -f "${ORACLE_BASE:-/opt/oracle}/cfgtoollogs/dbca/${sid}/${sid}.log" ]; then
    dbca_log="${ORACLE_BASE:-/opt/oracle}/cfgtoollogs/dbca/${sid}/${sid}.log"
  else
    dbca_log=""
  fi

  if [ -n "${dbca_log}" ] && grep -q "ORA-61851" "${dbca_log}" 2>/dev/null; then
    return 0
  fi

  if [ -z "${sid}" ]; then
    return 1
  fi

  alert_log=$(resolve_alert_log "${sid}")
  if [ -n "${alert_log}" ] && grep -q "ORA-61851 signalled during: ALTER DATABASE FLASHBACK ON" "${alert_log}" 2>/dev/null; then
    return 0
  fi

  return 1
}

advance_true_cache_to_apply_mode() {
  local db_state db_role db_open_mode rc elapsed timeout_seconds recovery_output

  timeout_seconds="${TRUECACHE_RECOVERY_ADVANCE_TIMEOUT_SECONDS:-180}"
  if ! [[ "${timeout_seconds}" =~ ^[0-9]+$ ]] || [ "${timeout_seconds}" -le 0 ]; then
    timeout_seconds=180
  fi

  seed_true_cache_tde_wallet_from_blob || return 1
  ensure_true_cache_wallet_root_bridge || return 1

  elapsed=0
  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    db_state=$(sqlplus -s / as sysdba <<'SQL'
set heading off
set feedback off
set pagesize 0
set verify off
SELECT database_role || '|' || open_mode FROM v$database;
exit;
SQL
)
    rc=$?
    if [ "${rc}" -eq 0 ]; then
      db_role=$(echo "${db_state}" | cut -d'|' -f1 | xargs)
      db_open_mode=$(echo "${db_state}" | cut -d'|' -f2- | xargs)
      break
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  if [ "${rc}" -ne 0 ]; then
    print_message "Unable to inspect True Cache state after DBCA failure; sqlplus exited with ${rc}."
    return "${rc}"
  fi

  if [ "${db_role}" != "TRUE CACHE" ]; then
    print_message "DBCA failed with ORA-61851 but local role is ${db_role}; not treating it as recoverable."
    return 1
  fi

  print_message "DBCA failed after reaching True Cache role=${db_role}, open_mode=${db_open_mode}. Advancing to READ ONLY WITH APPLY."

  elapsed=0
  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    recovery_output=$(sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON
DECLARE
   l_open_mode VARCHAR2(64);
BEGIN
   SELECT open_mode INTO l_open_mode FROM v$database;

   IF l_open_mode = 'MOUNTED' THEN
      DBMS_OUTPUT.PUT_LINE('Opening true cache database read only.');
      EXECUTE IMMEDIATE 'ALTER DATABASE OPEN READ ONLY';
      SELECT open_mode INTO l_open_mode FROM v$database;
   END IF;

   IF l_open_mode IN ('READ ONLY', 'READ ONLY WITH APPLY') THEN
      FOR pdb IN (
         SELECT name
           FROM v$pdbs
          WHERE name <> 'PDB$SEED'
            AND open_mode <> 'READ ONLY'
      ) LOOP
         DBMS_OUTPUT.PUT_LINE('Opening PDB ' || pdb.name || ' READ ONLY.');
         EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE "' || REPLACE(pdb.name, '"', '""') || '" OPEN READ ONLY';
      END LOOP;
   END IF;

   IF l_open_mode = 'READ ONLY' THEN
      DBMS_OUTPUT.PUT_LINE('Starting managed recovery for true cache.');
      EXECUTE IMMEDIATE 'ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION';
   END IF;
END;
/
EXIT;
SQL
)
    rc=$?
    if [ "${rc}" -eq 0 ]; then
      return 0
    fi

    if printf '%s\n' "${recovery_output}" | grep -Eq 'ORA-01507|ORA-1507'; then
      print_message "True Cache recovery nudge hit ORA-1507; forcing local startup mount before retry."
      if ! sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
startup mount force;
exit
SQL
      then
        print_message "startup mount force failed while recovering True Cache; retrying."
      fi
    fi

    print_message "True Cache recovery nudge attempt returned sqlplus exit ${rc}; retrying."
    sleep 5
    elapsed=$((elapsed + 5))
  done

  return "${rc:-1}"
}

wait_for_true_cache_apply_mode() {
  local elapsed timeout_seconds db_state rc

  timeout_seconds="${TRUECACHE_APPLY_READY_TIMEOUT_SECONDS:-120}"
  if ! [[ "${timeout_seconds}" =~ ^[0-9]+$ ]] || [ "${timeout_seconds}" -le 0 ]; then
    timeout_seconds=120
  fi

  elapsed=0
  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    db_state=$(sqlplus -s / as sysdba <<'SQL'
set heading off
set feedback off
set pagesize 0
set verify off
SELECT database_role || '|' || open_mode FROM v$database;
exit;
SQL
)
    rc=$?
    if [ "${rc}" -eq 0 ] && [ "$(echo "${db_state}" | xargs)" = "TRUE CACHE|READ ONLY WITH APPLY" ]; then
      print_message "True Cache reached READ ONLY WITH APPLY after DBCA flashback failure."
      return 0
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  print_message "Timed out waiting for True Cache to reach READ ONLY WITH APPLY after DBCA flashback failure."
  return 1
}

start_true_cache_flashback_watchdog() {
  (
    local elapsed timeout_seconds
    trap 'exit 0' TERM

    timeout_seconds="${TRUECACHE_FLASHBACK_WATCHDOG_TIMEOUT_SECONDS:-900}"
    if ! [[ "${timeout_seconds}" =~ ^[0-9]+$ ]] || [ "${timeout_seconds}" -le 0 ]; then
      timeout_seconds=900
    fi

    elapsed=0
    while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
      if is_true_cache_flashback_failure "$@"; then
        print_message "Detected ORA-61851 while DBCA is still active. Starting extension-side recovery in the background."
        advance_true_cache_to_apply_mode || exit 1
        wait_for_true_cache_apply_mode || exit 1
        exit 0
      fi

      sleep 5
      elapsed=$((elapsed + 5))
    done

    exit 0
  ) >/dev/null 2>&1 &

  TRUECACHE_FLASHBACK_WATCHDOG_PID=$!
  export TRUECACHE_FLASHBACK_WATCHDOG_PID
}

main() {
  local stdin_file rc

  if [ "${TRUE_CACHE:-}" != "true" ]; then
    exec "${TRUECACHE_REAL_DBCA_PATH}" "$@"
  fi

  case " $* " in
    *" -createTrueCacheInstance "*|*" -createTrueCache "*) ;;
    *)
      exec "${TRUECACHE_REAL_DBCA_PATH}" "$@"
      ;;
  esac

  if [ -n "${TRUECACHE_DBCA_INIT_PARAMS:-}" ]; then
    set -- "$@" -initParams "${TRUECACHE_DBCA_INIT_PARAMS}"
  fi

  if [ "${TDE_ENABLED:-false}" = "true" ] && [ -n "${TDE_WALLET_PWD:-}" ] && ! has_arg "-sourceTdeWalletPassword" "$@"; then
    set -- "$@" -sourceTdeWalletPassword "${TDE_WALLET_PWD}"
    print_message "Passing source TDE wallet password to DBCA with -sourceTdeWalletPassword."
  fi

  stdin_file=$(mktemp "${TMPDIR:-/tmp}/truecache-dbca-stdin.XXXXXX") || exit 1
  trap 'rm -f "${stdin_file}"' EXIT
  cat > "${stdin_file}"
  normalize_true_cache_dbca_stdin_for_wallet_auth "${stdin_file}" "$@" || exit 1

  start_true_cache_flashback_watchdog "$@"
  trap 'rm -f "${stdin_file}"; if [ -n "${TRUECACHE_FLASHBACK_WATCHDOG_PID:-}" ]; then kill "${TRUECACHE_FLASHBACK_WATCHDOG_PID}" >/dev/null 2>&1 || true; fi' EXIT

  set +e
  "${TRUECACHE_REAL_DBCA_PATH}" "$@" < "${stdin_file}"
  rc=$?
  set -e

  if [ "${rc}" -eq 0 ]; then
    if [ -n "${TRUECACHE_FLASHBACK_WATCHDOG_PID:-}" ]; then
      kill "${TRUECACHE_FLASHBACK_WATCHDOG_PID}" >/dev/null 2>&1 || true
    fi
    exit 0
  fi

  if ! is_true_cache_flashback_failure "$@"; then
    exit "${rc}"
  fi

  print_message "Observed ORA-61851 from DBCA flashback enablement on True Cache. Applying extension-side recovery."

  if ! advance_true_cache_to_apply_mode; then
    exit "${rc}"
  fi

  if ! wait_for_true_cache_apply_mode; then
    exit "${rc}"
  fi

  exit 0
}

main "$@"
EOF

  chmod 700 "${TRUECACHE_DBCA_SHIM_DIR}/dbca" || return 1
  export PATH="${TRUECACHE_DBCA_SHIM_DIR}:${PATH}"
  print_message "Installed True Cache DBCA shim at ${TRUECACHE_DBCA_SHIM_DIR}/dbca."
}

prepare_true_cache_dbca_listener || exit 1
pin_primary_connect_string_for_rac
prepare_true_cache_dbca_args || exit 1
start_true_cache_dbca_listener || exit 1
wait_for_true_cache_external_callback || exit 1
stop_true_cache_dbca_listener_for_dbca || exit 1
disable_local_dbca_credential_wallet_for_true_cache
install_true_cache_dbca_shim || exit 1

exec "$(dirname "$0")/createDB.sh" "$@"
