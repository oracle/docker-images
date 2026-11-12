#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
# Since: Sep, 2026
# Author: paramdeep.saini@oracle.com
# Description: Apply supported PDB-level database parameters.

set -euo pipefail

SQLPLUS_BIN="${SQLPLUS_BIN:-sqlplus}"
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

function apply_max_string_size() {
  local value="$1"

  case "$value" in
    STANDARD|EXTENDED) ;;
    *) die "MAX_STRING_SIZE must be STANDARD or EXTENDED" ;;
  esac

  "$SQLPLUS_BIN" -s "/ as sysdba" <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF ECHO OFF
ALTER SESSION SET CONTAINER = "$PDB_NAME";
ALTER SYSTEM SET MAX_STRING_SIZE = $value SCOPE=SPFILE;
SELECT 'PDB_PARAMETER_APPLIED MAX_STRING_SIZE=' || '$value' FROM dual;
EXIT
SQL
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
