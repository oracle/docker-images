#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: June, 2026
# Description: Guard TDE_WALLET_PWD env-first contract across SingleInstance helpers.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TEST_TMPDIR}"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run_env_first_check() {
  local helper_file="$1"

  (
    set -euo pipefail
    unset TDE_WALLET_PWD ORACLE_TDE_SECRET_FILE ORACLE_TDE_PWD_SECRET_NAME SECRET_VOLUME
    source "${helper_file}"
    export TDE_WALLET_PWD="SecretPwd1"
    tde_require_primary_password
    [[ "${TDE_WALLET_PWD}" == "SecretPwd1" ]]
  ) || fail "expected env-only TDE_WALLET_PWD flow to pass for ${helper_file}"
}

run_secret_file_check() {
  local helper_file="$1"
  local version_name="$2"
  local secret_dir="${TEST_TMPDIR}/${version_name}"
  local secret_file="${secret_dir}/tde_wallet_pwd"

  mkdir -p "${secret_dir}"
  printf 'SecretFromFile1' > "${secret_file}"

  (
    set -euo pipefail
    unset TDE_WALLET_PWD ORACLE_TDE_SECRET_FILE ORACLE_TDE_PWD_SECRET_NAME
    export SECRET_VOLUME="${secret_dir}"
    source "${helper_file}"
    tde_require_primary_password
    [[ "${TDE_WALLET_PWD}" == "SecretFromFile1" ]]
    [[ "${ORACLE_TDE_SECRET_FILE}" == "${secret_file}" ]]
  ) || fail "expected secret-file TDE flow to pass for ${helper_file}"
}

for version in 19.3.0 23.26.0 26.0.0; do
  helper_file="${REPO_ROOT}/dockerfiles/${version}/tdeSecretUtils.sh"
  run_env_first_check "${helper_file}"
  run_secret_file_check "${helper_file}" "${version}"
done

echo "PASS: tdeWalletPwdEnvContract_test"
