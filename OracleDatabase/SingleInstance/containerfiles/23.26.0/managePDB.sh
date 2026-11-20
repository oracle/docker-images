#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
# Since: Sep, 2026
# Author: paramdeep.saini@oracle.com
# Description: Apply and verify supported PDB-level database parameters.
#
# MAX_STRING_SIZE=EXTENDED requires the documented upgrade-mode bounce:
#   OPEN UPGRADE -> SET SCOPE=SPFILE -> CLOSE -> OPEN UPGRADE -> utl32k.sql
#   -> CLOSE -> OPEN -> utlrp.sql -> verify

set -euo pipefail

SQLPLUS_BIN="${SQLPLUS_BIN:-sqlplus}"
# 23.26 and 26ai Single Instance images install under product/26ai/dbhome_1.
ORACLE_HOME="${ORACLE_HOME:-/opt/oracle/product/26ai/dbhome_1}"
UTL32K_SQL="${UTL32K_SQL:-${ORACLE_HOME}/rdbms/admin/utl32k.sql}"
UTLRP_SQL="${UTLRP_SQL:-${ORACLE_HOME}/rdbms/admin/utlrp.sql}"
OPERATION=""
PDB_NAME=""
declare -a PARAMETERS=()

function usage() {
  cat <<'EOF'
Usage:
  managePDB.sh --operation apply-parameters --pdb <PDB_NAME> --parameter <NAME=VALUE> [--parameter <NAME=VALUE> ...]

Options:
  --operation   PDB operation to execute. Currently: apply-parameters.
  --pdb         Target PDB name.
  --parameter   PDB parameter assignment. Repeat for multiple parameters.
  --help        Show this help.

Environment:
  SQLPLUS_BIN   SQL*Plus executable (default: sqlplus).
  UTL32K_SQL    Oracle utl32k.sql path (default: ORACLE_HOME/rdbms/admin/utl32k.sql).
  UTLRP_SQL     Oracle utlrp.sql path (default: ORACLE_HOME/rdbms/admin/utlrp.sql).
EOF
}

function die() {
  echo "ERROR: $*" >&2
  exit 1
}

function require_option_value() {
  [[ $# -ge 2 && -n "$2" ]] || die "Missing value for $1"
}

function validate_pdb_name() {
  [[ "$1" =~ ^[[:alpha:]][[:alnum:]_$#]*$ ]] ||
    die "Invalid PDB name: $1"
}

function add_parameter() {
  local assignment="$1"
  local name value existing

  [[ "$assignment" == *=* ]] || die "Parameter must use NAME=VALUE syntax: $assignment"
  name="${assignment%%=*}"
  value="${assignment#*=}"
  name="$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')"
  value="$(printf '%s' "$value" | tr '[:lower:]' '[:upper:]')"

  [[ "$name" =~ ^[[:alpha:]_][[:alnum:]_$#]*$ ]] ||
    die "Invalid parameter name: $name"
  [[ -n "$value" ]] || die "Parameter value cannot be empty: $name"

  for existing in "${PARAMETERS[@]}"; do
    [[ "${existing%%=*}" != "$name" ]] || die "Parameter specified more than once: $name"
  done
  PARAMETERS+=("$name=$value")
}

function run_sql() {
  # Fail hard on SQL/OS errors; do not continue nested scripts after a failure.
  "$SQLPLUS_BIN" -L -s "/ as sysdba" <<SQL
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF ECHO OFF
$1
EXIT
SQL
}

function pdb_max_string_size() {
  local value

  value=$(run_sql "
ALTER SESSION SET CONTAINER = \"$PDB_NAME\";
SELECT UPPER(TRIM(value)) FROM v\$parameter WHERE name = 'max_string_size';
") || die "SQL*Plus query failed while reading MAX_STRING_SIZE for PDB $PDB_NAME"

  printf '%s\n' "$value" | awk 'NF { value=$0 } END { print value }'
}

function pdb_compatible() {
  local value

  value=$(run_sql "
ALTER SESSION SET CONTAINER = \"$PDB_NAME\";
SELECT TRIM(value) FROM v\$parameter WHERE name = 'compatible';
") || die "SQL*Plus query failed while reading COMPATIBLE for PDB $PDB_NAME"

  printf '%s\n' "$value" | awk 'NF { value=$0 } END { print value }'
}

function require_supported_compatible() {
  local compatible="$1"
  local major="${compatible%%.*}"

  [[ "$major" =~ ^[0-9]+$ && "$major" -ge 12 ]] ||
    die "MAX_STRING_SIZE=EXTENDED requires COMPATIBLE >= 12.0.0.0; PDB $PDB_NAME has ${compatible:-empty}"
}

function verify_pdb_max_string_size() {
  local expected="$1"
  local actual

  actual="$(pdb_max_string_size)"
  [[ "$actual" == "$expected" ]] ||
    die "MAX_STRING_SIZE verification failed for PDB $PDB_NAME: expected $expected, got ${actual:-empty}"
  echo "PDB_PARAMETER_VERIFIED MAX_STRING_SIZE=$actual PDB=$PDB_NAME"
}

function close_pdb_ignore_already_closed() {
  run_sql "
ALTER SESSION SET CONTAINER = CDB\$ROOT;
BEGIN
  EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE \"$PDB_NAME\" CLOSE IMMEDIATE';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-65020: PDB already closed
    IF SQLCODE != -65020 THEN
      RAISE;
    END IF;
END;
/
"
}

function open_pdb_upgrade() {
  run_sql "
ALTER SESSION SET CONTAINER = CDB\$ROOT;
ALTER PLUGGABLE DATABASE \"$PDB_NAME\" OPEN UPGRADE;
"
}

function open_pdb_normal() {
  run_sql "
ALTER SESSION SET CONTAINER = CDB\$ROOT;
ALTER PLUGGABLE DATABASE \"$PDB_NAME\" OPEN;
"
}

function migrate_max_string_size_to_extended() {
  local pdb_value="$1"
  local compatible

  [[ -f "$UTL32K_SQL" ]] ||
    die "Required Oracle migration script not found: $UTL32K_SQL"
  [[ -f "$UTLRP_SQL" ]] ||
    die "Required Oracle recompilation script not found: $UTLRP_SQL"

  compatible="$(pdb_compatible)"
  require_supported_compatible "$compatible"

  echo "MAX_STRING_SIZE migration required: PDB=${pdb_value:-empty} target=EXTENDED"
  echo "Running the PDB upgrade-mode migration for $PDB_NAME with COMPATIBLE=$compatible"

  # Step 1: open upgrade and persist EXTENDED to the PDB SPFILE only.
  close_pdb_ignore_already_closed
  open_pdb_upgrade
  run_sql "
ALTER SESSION SET CONTAINER = \"$PDB_NAME\";
ALTER SYSTEM SET MAX_STRING_SIZE = EXTENDED SCOPE=SPFILE;
SELECT 'MAX_STRING_SIZE written to SPFILE for PDB=' || SYS_CONTEXT('USERENV', 'CON_NAME') FROM dual;
"

  # Step 2: bounce back into UPGRADE so EXTENDED is active in memory, then migrate.
  close_pdb_ignore_already_closed
  open_pdb_upgrade
  run_sql "
ALTER SESSION SET CONTAINER = \"$PDB_NAME\";
DECLARE
  l_value VARCHAR2(30);
BEGIN
  SELECT UPPER(TRIM(value)) INTO l_value FROM v\$parameter WHERE name = 'max_string_size';
  IF l_value <> 'EXTENDED' THEN
    raise_application_error(-20001,
      'MAX_STRING_SIZE not EXTENDED in upgrade mode before utl32k.sql; actual=' || l_value);
  END IF;
END;
/
@$UTL32K_SQL
SELECT 'UTL32K completed for PDB=' || SYS_CONTEXT('USERENV', 'CON_NAME') FROM dual;
"

  # Step 3: open normally and recompile.
  close_pdb_ignore_already_closed
  open_pdb_normal
  run_sql "
ALTER SESSION SET CONTAINER = \"$PDB_NAME\";
@$UTLRP_SQL
DECLARE
  l_value VARCHAR2(30);
BEGIN
  SELECT UPPER(TRIM(value)) INTO l_value FROM v\$parameter WHERE name = 'max_string_size';
  IF l_value <> 'EXTENDED' THEN
    raise_application_error(-20001,
      'MAX_STRING_SIZE verification failed after open; actual value is ' || l_value);
  END IF;
END;
/
SELECT 'PDB_PARAMETER_APPLIED MAX_STRING_SIZE=EXTENDED PDB=' || SYS_CONTEXT('USERENV', 'CON_NAME') FROM dual;
"

  verify_pdb_max_string_size EXTENDED
}

function apply_max_string_size() {
  local value="$1"
  local current_pdb

  case "$value" in
    STANDARD|EXTENDED) ;;
    *) die "MAX_STRING_SIZE must be STANDARD or EXTENDED" ;;
  esac

  current_pdb="$(pdb_max_string_size)"

  if [[ "$value" == "STANDARD" ]]; then
    if [[ "$current_pdb" == "EXTENDED" ]]; then
      die "MAX_STRING_SIZE cannot be changed from EXTENDED to STANDARD"
    fi
    [[ "$current_pdb" == "STANDARD" ]] ||
      die "MAX_STRING_SIZE verification failed for PDB $PDB_NAME: expected STANDARD, got ${current_pdb:-empty}"
    echo "PDB_PARAMETER_ALREADY_APPLIED MAX_STRING_SIZE=STANDARD PDB=$PDB_NAME"
    return 0
  fi

  if [[ "$current_pdb" == "EXTENDED" ]]; then
    verify_pdb_max_string_size EXTENDED
    return 0
  fi

  migrate_max_string_size_to_extended "$current_pdb"
}

function apply_parameter() {
  local assignment="$1"
  local name="${assignment%%=*}"
  local value="${assignment#*=}"

  case "$name" in
    MAX_STRING_SIZE)
      apply_max_string_size "$value"
      ;;
    *)
      die "Unsupported PDB parameter: $name"
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --operation)
      require_option_value "$@"
      OPERATION="$2"
      shift 2
      ;;
    --pdb)
      require_option_value "$@"
      PDB_NAME="$2"
      shift 2
      ;;
    --parameter)
      require_option_value "$@"
      add_parameter "$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ "$OPERATION" == "apply-parameters" ]] ||
  die "--operation must be apply-parameters"
[[ -n "$PDB_NAME" ]] || die "--pdb is required"
validate_pdb_name "$PDB_NAME"
(( ${#PARAMETERS[@]} > 0 )) || die "At least one --parameter is required"

for parameter in "${PARAMETERS[@]}"; do
  apply_parameter "$parameter"
done
