#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
# Since: Feb, 2026
# Author: paramdeep.saini@oracle.com
# Description: Manage tnsnames.ora aliases (upsert/delete) with optional strict de-duplication.

set -euo pipefail

# Default wallet directory used for TCPS when none is provided.
DEFAULT_WALLET_DIRECTORY="/opt/oracle/dg-wallet/sidb-standby-dg-client-wallet"

# Print the CLI syntax and supported options for alias management.
# Keep help text in one place so validation errors can point here.
function usage() {
  cat <<'EOF'
Usage:
  manageTnsAliases.sh --file <tnsnames.ora> --alias <ALIAS> --upsert --host <HOST> [--protocol <TCP|TCPS>] [--port <PORT>] --service <SERVICE> [--ssl-server-dn <DN>] [--my-wallet-directory <DIR>] [--strict-dedupe]
  manageTnsAliases.sh --file <tnsnames.ora> --alias <ALIAS> --delete [--strict-dedupe]

Options:
  --file                 Target tnsnames.ora file path.
  --alias                Alias name to manage.
  --upsert               Insert or replace alias block.
  --delete               Remove alias block(s).
  --host                 Host/FQDN for connect descriptor (required for --upsert).
  --protocol             Connect protocol: TCP or TCPS (default: TCP).
  --port                 Listener port for connect descriptor (default: 1521 for TCP, 2484 for TCPS).
  --service              SERVICE_NAME for connect descriptor (required for --upsert).
  --ssl-server-dn        Optional SSL_SERVER_CERT_DN for strict DN match.
  --my-wallet-directory  Wallet directory used in TCPS SECURITY block.
  --strict-dedupe        Remove both managed and unmanaged duplicates before action.
  --help                 Show this help.

Environment:
  MY_WALLET_DIRECTORY    Fallback wallet directory used for TCPS when --my-wallet-directory is not provided.
EOF
}

# Emit a consistent fatal error message and stop processing.
# Send errors to stderr so callers can separate them from file output.
function die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Convert an alias into a safe marker token for managed block comments.
# Restrict markers to alnum and underscore so regex handling stays simple.
function sanitize_marker_alias() {
  printf '%s' "$1" | tr -c '[:alnum:]_' '_'
}

# Remove previously managed alias blocks for a single alias.
# Preserve all unmanaged content while stripping generated markers.
function remove_managed_alias_blocks() {
  local file="$1"
  local alias_name="$2"
  local marker_alias begin_marker end_marker tmp_file
  marker_alias="$(sanitize_marker_alias "$alias_name")"
  begin_marker="# BEGIN AUTO_TNS_${marker_alias}"
  end_marker="# END AUTO_TNS_${marker_alias}"

  tmp_file="$(mktemp)"
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin {skip=1; next}
    $0 == end {skip=0; next}
    !skip {print}
  ' "$file" > "$tmp_file"
  mv "$tmp_file" "$file"
}

# Remove legacy unmanaged alias entries that match the target alias.
# Stop skipping once the next top-level alias definition begins.
function remove_legacy_alias_blocks() {
  local file="$1"
  local alias_name="$2"
  local tmp_file
  tmp_file="$(mktemp)"

  awk -v target_alias="$alias_name" '
    function trim_spaces(s) {
      gsub(/^[[:space:]]+/, "", s)
      gsub(/[[:space:]]+$/, "", s)
      return s
    }
    function starts_with_alias(line, lhs, pos) {
      if (line ~ /^[[:space:]]*#/) return 0
      if (line ~ /^[[:space:]]*$/) return 0
      if (line ~ /^[[:space:]]*\(/) return 0
      pos = index(line, "=")
      if (pos == 0) return 0
      lhs = substr(line, 1, pos - 1)
      lhs = trim_spaces(lhs)
      return (lhs != "")
    }
    function alias_name(line, lhs, pos) {
      pos = index(line, "=")
      lhs = substr(line, 1, pos - 1)
      return trim_spaces(lhs)
    }
    {
      if (!skip) {
        if (starts_with_alias($0) && alias_name($0) == target_alias) {
          skip = 1
          next
        }
        print
        next
      }
      if (starts_with_alias($0)) {
        if (alias_name($0) == target_alias) {
          next
        }
        print
        skip = 0
      }
    }
  ' "$file" > "$tmp_file"

  mv "$tmp_file" "$file"
}

# Resolve the wallet directory from CLI or environment, then fall back to the default.
function resolve_wallet_directory() {
  local wallet_directory="$1"

  if [[ -z "$wallet_directory" && -n "${MY_WALLET_DIRECTORY:-}" ]]; then
    wallet_directory="$MY_WALLET_DIRECTORY"
  fi

  if [[ -z "$wallet_directory" ]]; then
    wallet_directory="$DEFAULT_WALLET_DIRECTORY"
  fi

  printf '%s' "$wallet_directory"
}

# Sync generated tnsnames.ora to dbconfig path also.
# Broker/DMON may resolve aliases from /opt/oracle/oradata/dbconfig/<ORACLE_SID>/tnsnames.ora.
function sync_dbconfig_tnsnames_if_needed() {
  local source_file="$1"
  local db_unique_name="${ORACLE_SID:-}"
  local dbconfig_dir dbconfig_file source_real target_real

  if [[ -z "$db_unique_name" ]]; then
    return 0
  fi

  dbconfig_dir="/opt/oracle/oradata/dbconfig/${db_unique_name}"
  dbconfig_file="${dbconfig_dir}/tnsnames.ora"

  if [[ ! -d "$dbconfig_dir" ]]; then
    return 0
  fi

  source_real="$(readlink -f "$source_file" 2>/dev/null || printf '%s' "$source_file")"
  target_real="$(readlink -f "$dbconfig_file" 2>/dev/null || printf '%s' "$dbconfig_file")"

  # If both paths already resolve to the same file, nothing to sync.
  if [[ "$source_real" == "$target_real" ]]; then
    return 0
  fi

  cp "$source_file" "$dbconfig_file"
}

# Append a normalized managed alias block to the target tnsnames.ora file.
# Include the optional TCPS security stanza always for TCPS.
function append_managed_alias_block() {
  local file="$1"
  local alias_name="$2"
  local host="$3"
  local port="$4"
  local protocol="$5"
  local service_name="$6"
  local ssl_dn="$7"
  local wallet_directory="$8"
  local marker_alias begin_marker end_marker

  marker_alias="$(sanitize_marker_alias "$alias_name")"
  begin_marker="# BEGIN AUTO_TNS_${marker_alias}"
  end_marker="# END AUTO_TNS_${marker_alias}"

  if [ -s "$file" ]; then
    echo "" >> "$file"
  fi

  {
    echo "$begin_marker"
    echo "${alias_name}="
    echo "(DESCRIPTION="
    echo "  (ADDRESS="
    echo "    (PROTOCOL=${protocol})"
    echo "    (HOST=${host})"
    echo "    (PORT=${port})"
    echo "  )"
    echo "  (CONNECT_DATA="
    echo "    (SERVER=dedicated)"
    echo "    (SERVICE_NAME=${service_name})"
    echo "  )"
    if [[ "$protocol" == "TCPS" ]]; then
      echo "  (SECURITY="
      echo "    (SSL_SERVER_DN_MATCH=NO)"
      echo "    (MY_WALLET_DIRECTORY=${wallet_directory})"
      if [ -n "$ssl_dn" ]; then
        echo "    (SSL_SERVER_CERT_DN=${ssl_dn})"
      fi
      echo "  )"
    fi
    echo ")"
    echo "$end_marker"
  } >> "$file"
}

FILE=""
ALIAS_NAME=""
HOST=""
PORT=""
SERVICE_NAME=""
SSL_SERVER_DN=""
MY_WALLET_DIRECTORY_VALUE=""
PROTOCOL="TCP"
ACTION=""
STRICT_DEDUPE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE="$2"
      shift 2
      ;;
    --alias)
      ALIAS_NAME="$2"
      shift 2
      ;;
    --host)
      HOST="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --protocol)
      PROTOCOL="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"
      shift 2
      ;;
    --service)
      SERVICE_NAME="$2"
      shift 2
      ;;
    --ssl-server-dn)
      SSL_SERVER_DN="$2"
      shift 2
      ;;
    --my-wallet-directory)
      MY_WALLET_DIRECTORY_VALUE="$2"
      shift 2
      ;;
    --upsert)
      ACTION="upsert"
      shift
      ;;
    --delete)
      ACTION="delete"
      shift
      ;;
    --strict-dedupe)
      STRICT_DEDUPE=true
      shift
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

[[ -n "$FILE" ]] || die "--file is required"
[[ -n "$ALIAS_NAME" ]] || die "--alias is required"
[[ -n "$ACTION" ]] || die "Action is required: --upsert or --delete"
touch "$FILE"

if [[ "$ACTION" == "upsert" ]]; then
  [[ -n "$HOST" ]] || die "--host is required for --upsert"
  case "$PROTOCOL" in
    TCP|TCPS) ;;
    *) die "--protocol must be TCP or TCPS" ;;
  esac
  if [[ -z "$PORT" ]]; then
    if [[ "$PROTOCOL" == "TCPS" ]]; then
      PORT="2484"
    else
      PORT="1521"
    fi
  fi
  if [[ "$PROTOCOL" == "TCP" && -n "$SSL_SERVER_DN" ]]; then
    die "--ssl-server-dn is valid only when --protocol TCPS is used"
  fi
  [[ -n "$SERVICE_NAME" ]] || die "--service is required for --upsert"
fi

# Always remove managed copies first so updates are idempotent.
remove_managed_alias_blocks "$FILE" "$ALIAS_NAME"

# Strict mode also removes unmanaged/legacy duplicate stanzas for this alias.
if [[ "$STRICT_DEDUPE" == "true" ]]; then
  remove_legacy_alias_blocks "$FILE" "$ALIAS_NAME"
fi

if [[ "$ACTION" == "upsert" ]]; then
  RESOLVED_WALLET_DIRECTORY=""
  if [[ "$PROTOCOL" == "TCPS" ]]; then
    RESOLVED_WALLET_DIRECTORY="$(resolve_wallet_directory "$MY_WALLET_DIRECTORY_VALUE")"
  fi
  append_managed_alias_block "$FILE" "$ALIAS_NAME" "$HOST" "$PORT" "$PROTOCOL" "$SERVICE_NAME" "$SSL_SERVER_DN" "$RESOLVED_WALLET_DIRECTORY"
fi

# Keep dbconfig tnsnames.ora in sync with the file updated by this script.
sync_dbconfig_tnsnames_if_needed "$FILE"