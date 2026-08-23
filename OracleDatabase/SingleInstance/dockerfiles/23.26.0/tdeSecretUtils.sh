#!/bin/bash
# Shared TDE secret resolution helpers for runOracle.sh and createDB.sh.

# Initialize defaults used by TDE secret handling.
function tde_init_defaults {
  SECRET_VOLUME="${SECRET_VOLUME:-/run/secrets}"
  ORACLE_TDE_PWD_SECRET_NAME="${ORACLE_TDE_PWD_SECRET_NAME:-tde_wallet_pwd}"
  export SECRET_VOLUME ORACLE_TDE_PWD_SECRET_NAME
}

# Resolve ORACLE_TDE_SECRET_FILE with precedence:
# 1) Explicit ORACLE_TDE_SECRET_FILE, if it points to an existing file
# 2) fallback_path, if provided and points to an existing file
# 3) ${SECRET_VOLUME}/${default_file_name}
# Returns 0 when a resolved file exists, 1 otherwise.
function tde_resolve_secret_file {
  local fallback_path="${1:-}"
  local default_file_name="${2:-}"

  tde_init_defaults
  if [[ -z "${default_file_name}" ]]; then
    default_file_name="${ORACLE_TDE_PWD_SECRET_NAME}"
  fi

  if [[ -n "${ORACLE_TDE_SECRET_FILE:-}" ]] && [[ -f "${ORACLE_TDE_SECRET_FILE}" ]]; then
    export ORACLE_TDE_SECRET_FILE
    return 0
  fi

  if [[ -n "${fallback_path}" ]] && [[ -f "${fallback_path}" ]]; then
    ORACLE_TDE_SECRET_FILE="${fallback_path}"
    export ORACLE_TDE_SECRET_FILE
    return 0
  fi

  ORACLE_TDE_SECRET_FILE="${SECRET_VOLUME}/${default_file_name}"
  export ORACLE_TDE_SECRET_FILE
  [[ -f "${ORACLE_TDE_SECRET_FILE}" ]]
}

# Resolve and validate standby wallet zip artifact.
# Returns 0 when a valid zip file is resolved, 1 otherwise.
function tde_require_standby_wallet_zip {
  local fallback_path="${1:-}"
  if ! tde_resolve_secret_file "${fallback_path}" "standby-wallet.zip"; then
    echo "ERROR: STANDBY_DB=true and TDE_ENABLED=true but no standby wallet zip file was found. Exiting..."
    return 1
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    echo "ERROR: unzip utility is required to extract standby TDE wallet artifact. Exiting..."
    return 1
  fi

  if ! unzip -tq "${ORACLE_TDE_SECRET_FILE}" >/dev/null 2>&1; then
    echo "ERROR: Standby TDE wallet artifact is not a valid zip file. Exiting..."
    return 1
  fi

  return 0
}

# Resolve and validate primary TDE wallet password.
# Returns 0 when TDE_WALLET_PWD is loaded and non-empty, 1 otherwise.
function tde_require_primary_password {
  local fallback_path="${1:-}"
  local default_file_name="${2:-}"

  if [[ -n "${TDE_WALLET_PWD:-}" ]]; then
    export TDE_WALLET_PWD
    return 0
  fi

  if ! tde_resolve_secret_file "${fallback_path}" "${default_file_name}"; then
    echo "ERROR: TDE_ENABLED=true but TDE password not found. Set TDE_WALLET_PWD or provide ORACLE_TDE_SECRET_FILE (fallback: SECRET_VOLUME/ORACLE_TDE_PWD_SECRET_NAME). Exiting..."
    return 1
  fi

  TDE_WALLET_PWD="$(cat "${ORACLE_TDE_SECRET_FILE}")"
  export TDE_WALLET_PWD

  if [[ -z "${TDE_WALLET_PWD}" ]]; then
    echo "ERROR: TDE wallet password is empty. Exiting..."
    return 1
  fi

  # Guardrail: a standby wallet zip should not be consumed as primary TDE password.
  if command -v unzip >/dev/null 2>&1 && unzip -tq "${ORACLE_TDE_SECRET_FILE}" >/dev/null 2>&1; then
    echo "ERROR: ORACLE_TDE_SECRET_FILE points to a zip artifact; expected a password file for primary TDE. Exiting..."
    return 1
  fi

  return 0
}
