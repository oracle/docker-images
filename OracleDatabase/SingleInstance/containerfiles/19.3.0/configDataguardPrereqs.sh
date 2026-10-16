#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: April, 2026
# Author: paramdeep.saini@oracle.com
# Description: Configure Data Guard broker prerequisites and standby redo logs.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
ACTION="${1:-configure}"

if [ -z "${ORACLE_HOME:-}" ]; then
  echo "${SCRIPT_NAME}: ERROR - ORACLE_HOME is not set."
  exit 1
fi

if [ -z "${ORACLE_SID:-}" ]; then
  ORACLE_SID="$(awk -F: -v oracle_home="$ORACLE_HOME" '$2 == oracle_home { print $1; exit }' /etc/oratab 2>/dev/null || true)"
fi

if [ -z "${ORACLE_SID:-}" ]; then
  echo "${SCRIPT_NAME}: ERROR - ORACLE_SID is not set and could not be detected from /etc/oratab."
  exit 1
fi

ORACLE_SID="${ORACLE_SID^^}"
ORACLE_BASE="${ORACLE_BASE:-/opt/oracle}"
SQLPLUS_BIN="${ORACLE_HOME}/bin/sqlplus"
STANDBY_REDO_SIZE="$(printf '%s' "${STANDBY_REDO_SIZE:-200M}" | tr '[:lower:]' '[:upper:]')"
DG_BROKER_CONFIG_DIR="${DG_BROKER_CONFIG_DIR:-${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}}"
DG_ENABLE_BROKER="$(printf '%s' "${DG_ENABLE_BROKER:-true}" | tr '[:upper:]' '[:lower:]')"
DG_REDO_MODE="$(printf '%s' "${DG_REDO_MODE:-add-only}" | tr '[:upper:]' '[:lower:]')"

export ORACLE_SID ORACLE_BASE

if [ ! -x "${SQLPLUS_BIN}" ]; then
  echo "${SCRIPT_NAME}: ERROR - sqlplus not found at ${SQLPLUS_BIN}."
  exit 1
fi

if [ "${DG_REDO_MODE}" != "add-only" ]; then
  echo "${SCRIPT_NAME}: ERROR - unsupported DG_REDO_MODE=${DG_REDO_MODE}. Supported values: add-only."
  exit 1
fi

case "${DG_ENABLE_BROKER}" in
  true|false) ;;
  *)
    echo "${SCRIPT_NAME}: ERROR - DG_ENABLE_BROKER must be true or false."
    exit 1
    ;;
esac

case "${ACTION}" in
  configure|configure-net|status) ;;
  *)
    echo "Usage: ${SCRIPT_NAME} [configure|configure-net|status]"
    exit 1
    ;;
esac

# Escape single quotes before embedding values in SQL text.
# Keep the helper narrow so other SQL stays readable at call sites.
function sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

# Render the managed listener.ora block for the local DGMGRL service.
# Keep the block text centralized so refreshes stay deterministic.
function print_local_listener_block() {
  cat <<EOF
    # BEGIN AUTO_DG_DGMGRL_${ORACLE_SID}
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLE_SID}_DGMGRL)
      (SID_NAME = ${ORACLE_SID})
      (ORACLE_HOME = ${ORACLE_HOME})
      (ENVS="TNS_ADMIN=${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}")
    )
    # END AUTO_DG_DGMGRL_${ORACLE_SID}
EOF
}

# Insert or refresh the managed DGMGRL listener entry in listener.ora.
# Remove stale managed or duplicate SID_DESC blocks before writing.
function ensure_local_dgmgrl_listener_entry() {
  local listener_file tmp_file block
  listener_file="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/listener.ora"
  tmp_file="$(mktemp)"
  block="$(print_local_listener_block)"

  touch "${listener_file}"

  awk \
    -v marker_begin="# BEGIN AUTO_DG_DGMGRL_${ORACLE_SID}" \
    -v marker_end="# END AUTO_DG_DGMGRL_${ORACLE_SID}" \
    -v target_global="${ORACLE_SID}_DGMGRL" \
    -v managed_block="${block}" '
    function count_open(s, tmp) {
      tmp = s
      return gsub(/\(/, "", tmp)
    }
    function count_close(s, tmp) {
      tmp = s
      return gsub(/\)/, "", tmp)
    }
    function flush_sid_desc(    i, remove_block) {
      if (!capture_sid_desc) {
        return
      }
      remove_block = 0
      for (i = 1; i <= sid_desc_count; i++) {
        if (index(sid_desc_lines[i], marker_begin) > 0 || index(sid_desc_lines[i], marker_end) > 0) {
          remove_block = 1
          break
        }
        if (index(toupper(sid_desc_lines[i]), toupper(target_global)) > 0) {
          remove_block = 1
          break
        }
      }
      if (!remove_block) {
        for (i = 1; i <= sid_desc_count; i++) {
          print sid_desc_lines[i]
        }
      }
      delete sid_desc_lines
      sid_desc_count = 0
      sid_desc_depth = 0
      capture_sid_desc = 0
    }
    BEGIN {
      skip_managed = 0
      capture_sid_desc = 0
      sid_desc_count = 0
      sid_desc_depth = 0
      in_sid_list = 0
      sid_list_depth = 0
      inserted = 0
      found_sid_list = 0
    }
    {
      line = $0

      if (index(line, marker_begin) > 0) {
        skip_managed = 1
        next
      }
      if (skip_managed) {
        if (index(line, marker_end) > 0) {
          skip_managed = 0
        }
        next
      }

      if (capture_sid_desc) {
        sid_desc_lines[++sid_desc_count] = line
        sid_desc_depth += count_open(line) - count_close(line)
        if (sid_desc_depth <= 0) {
          flush_sid_desc()
        }
        next
      }

      if (line ~ /^[[:space:]]*\(SID_DESC[[:space:]]*=/ || line ~ /^[[:space:]]*\(SID_DESC[[:space:]]*$/) {
        capture_sid_desc = 1
        sid_desc_count = 1
        sid_desc_lines[sid_desc_count] = line
        sid_desc_depth = count_open(line) - count_close(line)
        if (sid_desc_depth <= 0) {
          flush_sid_desc()
        }
        next
      }

      if (line ~ /^[[:space:]]*\(SID_LIST[[:space:]]*=/ || line ~ /^[[:space:]]*\(SID_LIST[[:space:]]*$/) {
        found_sid_list = 1
        in_sid_list = 1
        sid_list_depth = count_open(line) - count_close(line)
        print line
        if (sid_list_depth <= 0 && !inserted) {
          print managed_block
          inserted = 1
          in_sid_list = 0
        }
        next
      }

      if (in_sid_list) {
        next_depth = sid_list_depth + count_open(line) - count_close(line)
        if (!inserted && next_depth <= 0) {
          print managed_block
          inserted = 1
        }
        print line
        sid_list_depth = next_depth
        if (sid_list_depth <= 0) {
          in_sid_list = 0
        }
        next
      }

      print line
    }
    END {
      flush_sid_desc()
      if (!found_sid_list) {
        print ""
        print "SID_LIST_LISTENER ="
        print "  (SID_LIST ="
        print managed_block
        print "  )"
      } else if (!inserted) {
        print managed_block
      }
    }
  ' "${listener_file}" > "${tmp_file}"

  if cmp -s "${listener_file}" "${tmp_file}"; then
    rm -f "${tmp_file}"
    return 1
  fi

  mv "${tmp_file}" "${listener_file}"
  return 0
}

# Apply local listener changes and bounce the listener only when needed.
# Leave the listener untouched when the managed block is already current.
function configure_local_dg_net() {
  local listener_changed=1

  if ensure_local_dgmgrl_listener_entry; then
    listener_changed=0
    echo "INFO: ensured Data Guard _DGMGRL listener entry"
  fi

  if [ "${listener_changed}" -eq 0 ]; then
    lsnrctl stop
    lsnrctl start
  fi
}

# Create the broker config directory when broker management is enabled.
# Use a stable location under dbconfig so broker files survive restarts.
function ensure_broker_config_dir() {
  if [ "${DG_ENABLE_BROKER}" != "true" ]; then
    return
  fi
  if [[ "${DG_BROKER_CONFIG_DIR}" == +* ]]; then
    return
  fi
  mkdir -p "${DG_BROKER_CONFIG_DIR}"
  chown oracle:oinstall "${DG_BROKER_CONFIG_DIR}" || true
  chmod 775 "${DG_BROKER_CONFIG_DIR}" || true
}

# Print broker-related parameter state for status and debugging.
# Keep the query isolated from configure flow for read-only inspection.
function run_status_sql() {
  "${SQLPLUS_BIN}" -s / as sysdba <<'EOF'
set pages 200 lines 200 trimspool on feedback on heading on verify off
col db_unique_name format a30
col name format a30
col value format a90
col open_mode format a20
col database_role format a20

prompt === DATABASE ROLE ===
select db_unique_name, database_role, open_mode from v$database;

prompt === DG BROKER PARAMETERS ===
show parameter dg_broker_start
show parameter dg_broker_config_file

prompt === ONLINE REDO LOG SUMMARY ===
select thread#, count(*) online_groups, round(max(bytes)/1024/1024) online_size_mb
from v$log
group by thread#
order by thread#;

prompt === STANDBY REDO LOG SUMMARY ===
select thread#, count(*) standby_groups, round(nvl(max(bytes), 0)/1024/1024) standby_size_mb
from v$standby_log
group by thread#
order by thread#;

prompt === STANDBY REDO LOG DETAIL ===
select group#, thread#, round(bytes/1024/1024) size_mb, status
from v$standby_log
order by thread#, group#;

prompt === MANAGED STANDBY ===
select process, status, thread#, sequence#
from v$managed_standby
order by process;
EOF
}

# Apply broker enablement and standby redo settings to the local database.
# Use add-only semantics so existing redo groups are left in place.
function run_configure_sql() {
  local escaped_config_dir
  local escaped_enable_broker
  local escaped_oradata_dir
  local escaped_redo_size

  escaped_config_dir="$(sql_escape "${DG_BROKER_CONFIG_DIR}")"
  escaped_enable_broker="$(sql_escape "${DG_ENABLE_BROKER}")"
  escaped_oradata_dir="$(sql_escape "${ORACLE_BASE}/oradata")"
  escaped_redo_size="$(sql_escape "${STANDBY_REDO_SIZE}")"

  "${SQLPLUS_BIN}" -s / as sysdba <<EOF
whenever sqlerror exit failure
set serveroutput on size unlimited feedback on verify off heading on pages 200 lines 200

declare
  l_database_role      v\$database.database_role%type;
  l_open_mode          v\$database.open_mode%type;
  l_db_unique_name     v\$parameter.value%type;
  l_apply_running      number := 0;
  l_restart_apply      boolean := false;
  l_target_srl_groups  number;
  l_missing_srl_groups number;
  l_config_dir         varchar2(4000) := '${escaped_config_dir}';
  l_broker_enabled     varchar2(5) := '${escaped_enable_broker}';
  l_oradata_dir        varchar2(4000) := '${escaped_oradata_dir}';
  l_redo_size          varchar2(64) := '${escaped_redo_size}';
  l_file1              varchar2(4000);
  l_file2              varchar2(4000);
begin
  select database_role, open_mode into l_database_role, l_open_mode from v\$database;
  select value into l_db_unique_name from v\$parameter where name = 'db_unique_name';

  dbms_output.put_line('INFO: db_unique_name=' || l_db_unique_name || ', database_role=' || l_database_role || ', open_mode=' || l_open_mode);

  execute immediate 'alter system set db_create_file_dest=''' || replace(l_oradata_dir, '''', '''''') || ''' scope=both sid=''*''';
  execute immediate 'alter system set db_create_online_log_dest_1=''' || replace(l_oradata_dir, '''', '''''') || ''' scope=both sid=''*''';
  execute immediate q'[alter system set standby_file_management='AUTO' scope=both sid='*']';
  dbms_output.put_line('INFO: configured Data Guard init parameters');

  if l_database_role != 'PHYSICAL STANDBY' then
    execute immediate 'alter system switch logfile';
    dbms_output.put_line('INFO: switched logfile after init parameter configuration');
  end if;

  if l_database_role = 'PHYSICAL STANDBY' then
    begin
      select count(*)
        into l_apply_running
        from v\$managed_standby
       where process like 'MRP%';
    exception
      when others then
        l_apply_running := 0;
    end;

    if l_apply_running > 0 then
      execute immediate 'alter database recover managed standby database cancel';
      l_restart_apply := true;
      dbms_output.put_line('INFO: cancelled managed standby recovery before standby redo log checks');
    end if;
  end if;

  if l_broker_enabled = 'true' then
    l_file1 := rtrim(l_config_dir, '/') || '/dr1' || l_db_unique_name || '.dat';
    l_file2 := rtrim(l_config_dir, '/') || '/dr2' || l_db_unique_name || '.dat';

    begin
      execute immediate q'[alter system set dg_broker_start=false scope=both sid='*']';
    exception
      when others then
        null;
    end;

    execute immediate 'alter system set dg_broker_config_file1=''' || replace(l_file1, '''', '''''') || ''' scope=both sid=''*''';
    execute immediate 'alter system set dg_broker_config_file2=''' || replace(l_file2, '''', '''''') || ''' scope=both sid=''*''';
    execute immediate q'[alter system set dg_broker_start=true scope=both sid='*']';
    dbms_output.put_line('INFO: configured Data Guard broker files');
    dbms_output.put_line('INFO: dg_broker_config_file1=' || l_file1);
    dbms_output.put_line('INFO: dg_broker_config_file2=' || l_file2);
  end if;

  for rec in (
    select l.thread#,
           count(*) online_groups,
           round(max(l.bytes)/1024/1024) online_size_mb,
           nvl((select count(*) from v\$standby_log sl where sl.thread# = l.thread#), 0) standby_groups
      from v\$log l
     group by l.thread#
     order by l.thread#
  ) loop
    l_target_srl_groups := rec.online_groups + 1;
    l_missing_srl_groups := greatest(l_target_srl_groups - rec.standby_groups, 0);

    dbms_output.put_line(
      'INFO: thread=' || rec.thread# ||
      ', online_groups=' || rec.online_groups ||
      ', standby_groups=' || rec.standby_groups ||
      ', target_standby_groups=' || l_target_srl_groups ||
      ', standby_redo_size=' || l_redo_size
    );

    for i in 1 .. l_missing_srl_groups loop
      execute immediate 'alter database add standby logfile thread ' || rec.thread# || ' size ' || l_redo_size;
      dbms_output.put_line('INFO: added standby redo log group for thread ' || rec.thread# || ' size ' || l_redo_size);
    end loop;
  end loop;

  if l_restart_apply then
    execute immediate 'alter database recover managed standby database using current logfile disconnect from session';
    dbms_output.put_line('INFO: restarted managed standby recovery');
  end if;

  execute immediate 'alter system register';
  dbms_output.put_line('INFO: alter system register completed');
end;
/

show parameter dg_broker_start
show parameter dg_broker_config_file

prompt === ONLINE REDO LOG SUMMARY ===
select thread#, count(*) online_groups, round(max(bytes)/1024/1024) online_size_mb
from v\$log
group by thread#
order by thread#;

prompt === STANDBY REDO LOG SUMMARY ===
select thread#, count(*) standby_groups, round(nvl(max(bytes), 0)/1024/1024) standby_size_mb
from v\$standby_log
group by thread#
order by thread#;
EOF
}

ensure_broker_config_dir

if [ "${ACTION}" = "status" ]; then
  run_status_sql
elif [ "${ACTION}" = "configure-net" ]; then
  configure_local_dg_net
else
  configure_local_dg_net
  run_configure_sql
fi
