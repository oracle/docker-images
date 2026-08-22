#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Sample primary-host script for True Cache primary-side service
#              registration. Copy this file to the primary host and allow the
#              Oracle software owner to execute it through DBMS_SCHEDULER.
#

set -euo pipefail

if [ "$#" -ne 7 ] && [ "$#" -ne 8 ]; then
  echo "Usage: $0 <PRIMARY_SVCNAME> <TC_SVCNAME> <PRIMARY_PDB_NAME> <TC_CONNECT_STR> <SOURCE_DB_NAME> <SOURCE_DB_UNIQUE_NAME> <PRIMARY_IS_RAC> [PASSWORD_OR_WALLET_SOURCE]" >&2
  exit 1
fi

PRIMARY_SVCNAME=$1
TC_SVCNAME=$2
PRIMARY_PDB_NAME=$3
TC_CONNECT_STR=$4
SOURCE_DB_NAME=$5
SOURCE_DB_UNIQUE_NAME=$6
PRIMARY_IS_RAC=$7
PASSWORD_SOURCE=${8:-}
DEBUG_LOG="/tmp/configure-primary-truecache-service.$(date +%Y%m%d-%H%M%S).$$.log"
TRUECACHE_ASSOCIATION_VISIBILITY_WAIT_SECONDS="${TRUECACHE_ASSOCIATION_VISIBILITY_WAIT_SECONDS:-20}"

print_message() {
  local now
  now=$(date +"%m-%d-%Y %T %Z")
  echo "${now} : configure-primary-truecache-service.sh : ${1:-Unknown message}"
}

log_debug_context() {
  local password_mode

  case "${PASSWORD_SOURCE}" in
    B64:*)
      password_mode="B64"
      ;;
    WALLET_PATH:*)
      password_mode="WALLET_PATH"
      ;;
    ""|NO_PASSWORD)
      password_mode="NO_PASSWORD"
      ;;
    *)
      password_mode="RAW_OR_EXECUTABLE"
      ;;
  esac

  {
    echo "=== tc helper debug ==="
    date -u
    hostname
    id
    echo "pwd=$(pwd)"
    echo "ORACLE_HOME=${ORACLE_HOME:-<unset>}"
    echo "ORACLE_SID=${ORACLE_SID:-<unset>}"
    echo "PATH=${PATH:-<unset>}"
    echo "PRIMARY_SVCNAME=${PRIMARY_SVCNAME}"
    echo "TC_SVCNAME=${TC_SVCNAME}"
    echo "PRIMARY_PDB_NAME=${PRIMARY_PDB_NAME}"
    echo "TC_CONNECT_STR=${TC_CONNECT_STR}"
    echo "SOURCE_DB_NAME=${SOURCE_DB_NAME}"
    echo "SOURCE_DB_UNIQUE_NAME=${SOURCE_DB_UNIQUE_NAME}"
    echo "PRIMARY_IS_RAC=${PRIMARY_IS_RAC}"
    echo "PASSWORD_MODE=${password_mode}"
    echo "DEBUG_LOG=${DEBUG_LOG}"
    echo "======================="
  } >> "${DEBUG_LOG}" 2>&1
}

log_debug_context

log_dbca_invocation() {
  local auth_mode=$1

  {
    echo "=== tc helper dbca invocation ==="
    date -u
    echo "DBCA_PATH=${DBCA_PATH:-<unset>}"
    echo "TRUECACHE_SERVICE_OPTION=${TRUECACHE_SERVICE_OPTION:-<unset>}"
    echo "SOURCE_DB=${SOURCE_DB:-<unset>}"
    echo "PRIMARY_SVCNAME=${PRIMARY_SVCNAME}"
    echo "TC_SVCNAME=${TC_SVCNAME}"
    echo "PRIMARY_PDB_NAME=${PRIMARY_PDB_NAME}"
    echo "TC_CONNECT_STR=${TC_CONNECT_STR}"
    echo "AUTH_MODE=${auth_mode}"
    if [ "${auth_mode}" = "wallet" ]; then
      echo "WALLET_PATH=${WALLET_PATH:-<unset>}"
    fi
    echo "DBCA_CMD=${DBCA_PATH:-dbca} -silent -configureDatabase ${TRUECACHE_SERVICE_OPTION:-<unset>} -sourceDB ${SOURCE_DB:-<unset>} -trueCacheConnectString ${TC_CONNECT_STR} -trueCacheServiceName ${TC_SVCNAME} -serviceName ${PRIMARY_SVCNAME} -pdbName ${PRIMARY_PDB_NAME}"
    echo "==============================="
  } >> "${DEBUG_LOG}" 2>&1
}

run_dbca_command() {
  local auth_mode=$1
  shift
  local dbca_output_log
  local rc
  local output_full
  local output_tail

  log_dbca_invocation "${auth_mode}"

  dbca_output_log="$(mktemp /tmp/configure-primary-truecache-service.dbca.XXXXXX.log)"

  if "$@" > "${dbca_output_log}" 2>&1; then
    output_full="$(cat "${dbca_output_log}")"
    printf '%s\n' "${output_full}"
    {
      echo "=== tc helper dbca result ==="
      date -u
      echo "AUTH_MODE=${auth_mode}"
      echo "DBCA_EXIT=0"
      echo "DBCA_OUTPUT<<EOF"
      printf '%s\n' "${output_full}"
      echo "EOF"
      echo "============================="
    } >> "${DEBUG_LOG}" 2>&1
    rm -f "${dbca_output_log}"
    return 0
  else
    rc=$?
  fi

  output_full="$(cat "${dbca_output_log}")"
  output_tail="$(tail -n 40 "${dbca_output_log}" 2>/dev/null || true)"

  if probe_truecache_service_already_configured; then
    print_message "DBCA reported a non-fatal post-configuration service-start race after the True Cache association became visible in PDB ${PRIMARY_PDB_NAME}. Treating the run as successful. exit=${rc}"
    log_truecache_configuration_state
    {
      echo "=== tc helper dbca result ==="
      date -u
      echo "AUTH_MODE=${auth_mode}"
      echo "DBCA_EXIT=${rc}"
      echo "DBCA_POSTCHECK=association_visible"
      echo "DBCA_OUTPUT<<EOF"
      printf '%s\n' "${output_full}"
      echo "EOF"
      echo "============================="
    } >> "${DEBUG_LOG}" 2>&1
    rm -f "${dbca_output_log}"
    return 0
  fi

  printf '%s\n' "${output_full}"
  {
    echo "=== tc helper dbca result ==="
    date -u
    echo "AUTH_MODE=${auth_mode}"
    echo "DBCA_EXIT=${rc}"
    echo "DBCA_OUTPUT_TAIL=${output_tail}"
    echo "============================="
  } >> "${DEBUG_LOG}" 2>&1
  rm -f "${dbca_output_log}"
  return "${rc}"
}

resolve_password() {
  case "${PASSWORD_SOURCE}" in
    ""|NO_PASSWORD|WALLET_PATH:*)
      return 0
      ;;
    B64:*)
      printf '%s' "${PASSWORD_SOURCE#B64:}" | base64 -d
      ;;
    *)
      if [ -x "${PASSWORD_SOURCE}" ]; then
        "${PASSWORD_SOURCE}"
      else
        printf '%s' "${PASSWORD_SOURCE}"
      fi
      ;;
  esac
}

resolve_wallet_path() {
  local wallet_path

  case "${PASSWORD_SOURCE}" in
    WALLET_PATH:*)
      wallet_path="${PASSWORD_SOURCE#WALLET_PATH:}"
      ;;
    *)
      wallet_path="${PRIMARY_TC_SERVICE_WALLET_PATH:-}"
      ;;
  esac

  if [ -n "${wallet_path}" ] && [ -f "${wallet_path}/ewallet.p12" ]; then
    printf '%s\n' "${wallet_path}"
    return 0
  fi

  return 1
}

resolve_dbca_path() {
  local candidate

  if [ -n "${ORACLE_HOME:-}" ] && [ -x "${ORACLE_HOME}/bin/dbca" ]; then
    echo "${ORACLE_HOME}/bin/dbca"
    return 0
  fi

  candidate="$(command -v dbca 2>/dev/null || true)"
  if [ -x "${candidate}" ]; then
    echo "${candidate}"
    return 0
  fi

  if [ -r /etc/oratab ]; then
    while IFS=: read -r _ home _; do
      [ -z "${home}" ] && continue
      [ "${home#\#}" != "${home}" ] && continue
      candidate="${home}/bin/dbca"
      if [ -x "${candidate}" ]; then
        echo "${candidate}"
        return 0
      fi
    done < /etc/oratab
  fi

  for candidate in /u01/app/oracle/product/*/*/bin/dbca /opt/oracle/product/*/*/bin/dbca; do
    if [ -x "${candidate}" ]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

resolve_dbca_truecache_option() {
  local dbca_path=$1
  local help_output

  help_output="$("${dbca_path}" -configureDatabase -help 2>&1)"

  if echo "${help_output}" | grep -q -- '-configureTrueCacheService'; then
    echo "-configureTrueCacheService"
    return 0
  fi

  if echo "${help_output}" | grep -q -- '-configureTrueCacheInstanceService'; then
    echo "-configureTrueCacheInstanceService"
    return 0
  fi

  return 1
}

resolve_source_db() {
  if is_rac_primary && [ -n "${SOURCE_DB_UNIQUE_NAME}" ]; then
    printf '%s\n' "${SOURCE_DB_UNIQUE_NAME}"
    return 0
  fi

  if [ -n "${SOURCE_DB_NAME}" ]; then
    printf '%s\n' "${SOURCE_DB_NAME}"
    return 0
  fi

  return 1
}

is_rac_primary() {
  [ "$(printf '%s' "${PRIMARY_IS_RAC}" | tr '[:upper:]' '[:lower:]')" = "true" ]
}

resolve_srvctl_path() {
  local srvctl_path

  srvctl_path="$(command -v srvctl 2>/dev/null || true)"
  if [ -x "${srvctl_path}" ]; then
    printf '%s\n' "${srvctl_path}"
    return 0
  fi

  return 1
}

rac_service_is_running() {
  local srvctl_path=$1
  local target_db=$2
  local status_output

  status_output="$("${srvctl_path}" status service -db "${target_db}" -service "${PRIMARY_SVCNAME}" 2>&1 || true)"
  printf '%s\n' "${status_output}" | grep -Eq 'is running on instance'
}

resolve_local_instance_sid() {
  local srvctl_path
  local target_db
  local host_name
  local short_host
  local status_output
  local instance_name
  local node_name
  local pmon_sid

  if [ -n "${ORACLE_SID:-}" ]; then
    printf '%s\n' "${ORACLE_SID}"
    return 0
  fi

  if ! is_rac_primary; then
    if [ -n "${SOURCE_DB_NAME}" ]; then
      printf '%s\n' "${SOURCE_DB_NAME}"
      return 0
    fi
    if [ -n "${SOURCE_DB_UNIQUE_NAME}" ]; then
      printf '%s\n' "${SOURCE_DB_UNIQUE_NAME}"
      return 0
    fi
    return 1
  fi

  srvctl_path="$(resolve_srvctl_path || true)"
  target_db="${SOURCE_DB_UNIQUE_NAME:-${SOURCE_DB_NAME}}"
  host_name="$(hostname)"
  short_host="$(hostname -s)"
  if [ -x "${srvctl_path}" ] && [ -n "${target_db}" ]; then
    status_output="$("${srvctl_path}" status database -db "${target_db}" 2>/dev/null || true)"
    while IFS= read -r line; do
      case "${line}" in
        Instance\ *\ is\ running\ on\ node\ *)
          instance_name="${line#Instance }"
          instance_name="${instance_name%% is running on node *}"
          node_name="${line##* node }"
          if [ "${node_name}" = "${host_name}" ] || [ "${node_name}" = "${short_host}" ]; then
            printf '%s\n' "${instance_name}"
            return 0
          fi
          ;;
      esac
    done <<< "${status_output}"
  fi

  pmon_sid="$(ps -eo args= 2>/dev/null | sed -n "s/.*ora_pmon_\\(${SOURCE_DB_NAME}[[:alnum:]_#$]*\\)$/\\1/p" | head -n 1)"
  if [ -n "${pmon_sid}" ]; then
    printf '%s\n' "${pmon_sid}"
    return 0
  fi

  return 1
}

ensure_primary_service_ready() {
  local srvctl_path
  local target_db
  local preferred_instances
  local start_output

  print_message "Ensuring primary service ${PRIMARY_SVCNAME} exists and is started in PDB ${PRIMARY_PDB_NAME}."

  if is_rac_primary; then
    srvctl_path="$(resolve_srvctl_path || true)"
    target_db="${SOURCE_DB_UNIQUE_NAME:-${SOURCE_DB_NAME}}"

    if [ ! -x "${srvctl_path}" ] || [ -z "${target_db}" ]; then
      echo "Unable to resolve srvctl or target database for RAC primary service management." >&2
      exit 1
    fi

    if ! "${srvctl_path}" config service -db "${target_db}" -service "${PRIMARY_SVCNAME}" >/dev/null 2>&1; then
      print_message "Primary service ${PRIMARY_SVCNAME} is not yet a CRS-managed RAC service. Removing any DBMS_SERVICE copy before srvctl add."
      "${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<EOF
whenever sqlerror exit failure
set define off heading off feedback off verify off echo off pagesize 0
alter session set container=${PRIMARY_PDB_NAME};
declare
  l_service_count number := 0;
begin
  select count(*)
    into l_service_count
    from all_services
   where upper(name) = upper('${PRIMARY_SVCNAME}');

  if l_service_count > 0 then
    begin
      dbms_service.stop_service('${PRIMARY_SVCNAME}');
    exception when others then null;
    end;
    dbms_service.delete_service('${PRIMARY_SVCNAME}');
  end if;
end;
/
exit
EOF

      preferred_instances="$("${srvctl_path}" config database -db "${target_db}" 2>/dev/null | awk -F': ' '/^Database instances:/ {gsub(/ /, "", $2); print $2}')"
      if [ -n "${preferred_instances}" ]; then
        "${srvctl_path}" add service -db "${target_db}" -service "${PRIMARY_SVCNAME}" -pdb "${PRIMARY_PDB_NAME}" -preferred "${preferred_instances}"
      else
        "${srvctl_path}" add service -db "${target_db}" -service "${PRIMARY_SVCNAME}" -pdb "${PRIMARY_PDB_NAME}"
      fi
    fi

    if rac_service_is_running "${srvctl_path}" "${target_db}"; then
      print_message "Primary service ${PRIMARY_SVCNAME} is already running as a CRS-managed RAC service."
    else
      start_output="$("${srvctl_path}" start service -db "${target_db}" -service "${PRIMARY_SVCNAME}" 2>&1)" || {
        if printf '%s\n' "${start_output}" | grep -Eq 'PRCR-1120|CRS-5702'; then
          print_message "Primary service ${PRIMARY_SVCNAME} start output indicates it is already running. Continuing. output=[${start_output}]"
        else
          printf '%s\n' "${start_output}" >&2
          exit 1
        fi
      }
    fi
    "${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<EOF
set define off heading off feedback off verify off echo off pagesize 0
alter system register;
exit
EOF
    return 0
  fi

  "${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<EOF
whenever sqlerror exit failure
set define off heading off feedback off verify off echo off pagesize 0
alter session set container=${PRIMARY_PDB_NAME};
declare
  l_service_count number := 0;
  l_active_count  number := 0;
begin
  select count(*)
    into l_service_count
    from all_services
   where upper(name) = upper('${PRIMARY_SVCNAME}');

  if l_service_count = 0 then
    dbms_service.create_service('${PRIMARY_SVCNAME}', '${PRIMARY_SVCNAME}');
  end if;

  select count(*)
    into l_active_count
    from v\$active_services
   where upper(name) = upper('${PRIMARY_SVCNAME}');

  if l_active_count = 0 then
    dbms_service.start_service('${PRIMARY_SVCNAME}');
  end if;
end;
/
alter system register;
exit
EOF
}

get_existing_truecache_association() {
  local association

  association="$("${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<EOF
set define off heading off feedback off verify off echo off pagesize 0
alter session set container=${PRIMARY_PDB_NAME};
select max(true_cache_service)
  from (
    select true_cache_service
      from all_services
     where upper(name) = upper('${PRIMARY_SVCNAME}')
    union all
    select true_cache_service
      from v\$active_services
     where upper(name) = upper('${PRIMARY_SVCNAME}')
  );
exit
EOF
)"
  printf '%s\n' "${association}" | tr -d '\r' | xargs
}

truecache_service_exists_in_primary_pdb() {
  local service_count

  service_count="$("${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<EOF
set define off heading off feedback off verify off echo off pagesize 0
alter session set container=${PRIMARY_PDB_NAME};
select count(*)
  from (
    select name
      from all_services
     where upper(name) = upper('${TC_SVCNAME}')
    union
    select name
      from v\$active_services
     where upper(name) = upper('${TC_SVCNAME}')
  );
exit
EOF
)"
  [ "$(printf '%s\n' "${service_count}" | tr -d '\r' | xargs)" = "1" ]
}

get_active_truecache_service_state() {
  local active_state

  active_state="$("${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<EOF
set define off heading off feedback off verify off echo off pagesize 0
alter session set container=${PRIMARY_PDB_NAME};
select trim(name) || ':' || trim(nvl(true_cache_service, '<none>'))
  from v\$active_services
 where upper(name) in (upper('${PRIMARY_SVCNAME}'), upper('${TC_SVCNAME}'))
    or upper(true_cache_service) = upper('${TC_SVCNAME}')
 order by 1;
exit
EOF
)"
  printf '%s\n' "${active_state}" | tr -d '\r' | xargs
}

log_truecache_configuration_state() {
  local association
  local active_state

  association="$(get_existing_truecache_association)"
  active_state="$(get_active_truecache_service_state)"
  print_message "Verified primary association state for ${PRIMARY_SVCNAME}: association=[${association:-<none>}] active=[${active_state:-<none>}]"
}

probe_truecache_service_already_configured() {
  local association

  association="$(printf '%s' "$(get_existing_truecache_association)" | tr '[:lower:]' '[:upper:]')"
  if [ "${association}" = "${TC_SVCNAME^^}" ] && truecache_service_exists_in_primary_pdb; then
    return 0
  fi

  return 1
}

truecache_service_already_configured() {
  if probe_truecache_service_already_configured; then
    print_message "Primary service ${PRIMARY_SVCNAME} is already associated with True Cache service ${TC_SVCNAME}, and the True Cache service already exists in PDB ${PRIMARY_PDB_NAME}. Skipping DBCA rerun."
    log_truecache_configuration_state
    return 0
  fi

  return 1
}

wait_for_existing_truecache_configuration() {
  local timeout_seconds
  local elapsed

  timeout_seconds="${TRUECACHE_ASSOCIATION_VISIBILITY_WAIT_SECONDS}"
  elapsed=0

  while [ "${elapsed}" -lt "${timeout_seconds}" ]; do
    if probe_truecache_service_already_configured; then
      print_message "Primary service ${PRIMARY_SVCNAME} association to True Cache service ${TC_SVCNAME} became visible after ${elapsed}s. Skipping DBCA rerun."
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  return 1
}

PASSWORD="$(resolve_password || true)"

DBCA_PATH="$(resolve_dbca_path)"
if [ ! -x "${DBCA_PATH}" ]; then
  echo "Unable to find dbca on this host." >&2
  exit 127
fi

EXPECTED_DB_OWNER="$(stat -c %U "${DBCA_PATH}" 2>/dev/null || true)"
CURRENT_OS_USER="$(id -un)"
if [ -n "${EXPECTED_DB_OWNER}" ] && [ "${CURRENT_OS_USER}" != "${EXPECTED_DB_OWNER}" ]; then
  echo "This helper must run as ${EXPECTED_DB_OWNER}, but it started as ${CURRENT_OS_USER}. Configure DBMS_SCHEDULER executable jobs to run as the Oracle DB software owner." >&2
  exit 1
fi

export ORACLE_HOME="${DBCA_PATH%/bin/dbca}"
export PATH="${ORACLE_HOME}/bin:/usr/bin:/bin"
export LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
export TNS_ADMIN="${TNS_ADMIN:-${ORACLE_HOME}/network/admin}"

ORACLE_SID="$(resolve_local_instance_sid || true)"
if [ -z "${ORACLE_SID}" ]; then
  echo "Unable to determine ORACLE_SID for local SYSDBA connectivity on this host." >&2
  exit 1
fi
export ORACLE_SID

TRUECACHE_SERVICE_OPTION="$(resolve_dbca_truecache_option "${DBCA_PATH}")"
if [ -z "${TRUECACHE_SERVICE_OPTION}" ]; then
  echo "Unable to determine the DBCA True Cache service option on this host." >&2
  exit 1
fi

SOURCE_DB="$(resolve_source_db)"
if [ -z "${SOURCE_DB}" ]; then
  echo "Unable to determine the primary source database for True Cache service configuration." >&2
  exit 1
fi

print_message "Using DBCA path ${DBCA_PATH}."
if srvctl_path="$(resolve_srvctl_path || true)"; [ -n "${srvctl_path}" ]; then
  print_message "Using srvctl path ${srvctl_path} for RAC primary service management."
fi
print_message "Sanitized PATH to keep only ORACLE_HOME runtime binaries first: ${PATH}"
print_message "Using ORACLE_SID ${ORACLE_SID} for local SYSDBA connectivity."
print_message "Using sourceDB ${SOURCE_DB} for True Cache service configuration."
if truecache_service_already_configured; then
  exit 0
fi
if wait_for_existing_truecache_configuration; then
  exit 0
fi
ensure_primary_service_ready
if truecache_service_already_configured; then
  exit 0
fi

WALLET_PATH="$(resolve_wallet_path || true)"

if [ -n "${WALLET_PATH}" ]; then
  print_message "Using mkstore wallet ${WALLET_PATH} for DBCA True Cache service configuration."
  run_dbca_command "wallet" \
    "${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_SERVICE_OPTION}" \
    -useWalletForDBCredentials true \
    -dbCredentialsWalletLocation "${WALLET_PATH}" \
    -sourceDB "${SOURCE_DB}" \
    -trueCacheConnectString "${TC_CONNECT_STR}" \
    -trueCacheServiceName "${TC_SVCNAME}" \
    -serviceName "${PRIMARY_SVCNAME}" \
    -pdbName "${PRIMARY_PDB_NAME}"
elif [ -n "${PASSWORD}" ]; then
  run_dbca_command "stdin_password" \
    "${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_SERVICE_OPTION}" \
    -sourceDB "${SOURCE_DB}" \
    -trueCacheConnectString "${TC_CONNECT_STR}" \
    -trueCacheServiceName "${TC_SVCNAME}" \
    -serviceName "${PRIMARY_SVCNAME}" \
    -pdbName "${PRIMARY_PDB_NAME}" <<< "${PASSWORD}"
else
  print_message "No PASSWORD_SOURCE or wallet path was provided. Running DBCA True Cache service configuration without stdin password."
  run_dbca_command "no_password" \
    "${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_SERVICE_OPTION}" \
    -sourceDB "${SOURCE_DB}" \
    -trueCacheConnectString "${TC_CONNECT_STR}" \
    -trueCacheServiceName "${TC_SVCNAME}" \
    -serviceName "${PRIMARY_SVCNAME}" \
    -pdbName "${PRIMARY_PDB_NAME}"
fi
