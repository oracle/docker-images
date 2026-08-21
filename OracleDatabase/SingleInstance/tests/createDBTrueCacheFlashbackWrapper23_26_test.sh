#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the extension-local True Cache DBCA flashback workaround.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"
RUNORACLE_FILE="${REPO_ROOT}/extensions/truecache/runOracle.sh"

if ! grep -Fq 'install_true_cache_dbca_shim()' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to install a DBCA shim in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'start_true_cache_flashback_watchdog()' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to start a flashback watchdog in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq "trap 'exit 0' TERM" "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper watchdog to exit cleanly on TERM in ${WRAPPER_FILE}" >&2
  exit 1
fi

if grep -Fq 'watchdog_pid=$(start_true_cache_flashback_watchdog' "${WRAPPER_FILE}"; then
  echo "FAIL: True Cache wrapper should not start the watchdog via blocking command substitution in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'Observed ORA-61851 from DBCA flashback enablement on True Cache.' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to recognize ORA-61851 flashback failures in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION" "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to reuse managed recovery SQL in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'did not support instance-specific connect' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to validate RAC instance-specific connect before pinning in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq "from gv\$instance inst" "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to derive RAC pinning from gv\\$instance in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'True Cache recovery nudge attempt returned sqlplus exit' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to retry recovery nudge failures such as transient ORA-1507 in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'startup mount force;' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to force a local startup mount on ORA-1507 in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'export PATH="${TRUECACHE_DBCA_SHIM_DIR}:${PATH}"' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to prepend the DBCA shim to PATH in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'ensure_true_cache_wallet_root_bridge()' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to bridge the db_unique_name wallet_root path in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'seed_true_cache_tde_wallet_from_blob()' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to seed the TDE wallet from the True Cache blob in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'seed_true_cache_tde_wallet_from_blob || return 1' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to seed the TDE wallet only inside post-DBCA recovery in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'tar -xzf "${TRUE_CACHE_BLOB}" -C "${sid_wallet_dir}" ewallet.p12' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to extract ewallet.p12 from the blob in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq '"${ORACLE_HOME}/bin/orapki" wallet create -wallet "${sid_wallet_dir}" -auto_login' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to create an auto-login wallet in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'Linked True Cache wallet_root ${wallet_root_link} -> ${sid_wallet_dir}.' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to log wallet_root bridge creation in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'ensure_true_cache_wallet_root_bridge' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to recreate wallet_root bridges on restart in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'if [[ -f "${ORACLE_BASE}/oradata/.${ORACLE_SID}${CHECKPOINT_FILE_EXTN}" ]]; then' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to gate wallet recreation to reused-PVC startup in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'tar -xzf "${TRUE_CACHE_BLOB}" -C "${sid_wallet_dir}" ewallet.p12' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to re-extract ewallet.p12 from the blob on restart in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq '"${ORACLE_HOME}/bin/orapki" wallet create -wallet "${sid_wallet_dir}" -auto_login' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to recreate the auto-login wallet on restart in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'wallet_root_dir="${ORACLE_BASE}/admin/${target_unique_name}/wallet_root"' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to target the db_unique_name wallet_root path in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'prepare_true_cache_storage_alias()' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to own the TRUEDB_UNIQUE_NAME storage alias in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'target_dir_name="$(true_cache_storage_dir_name)"' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to derive the storage dir from TRUEDB_UNIQUE_NAME in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'ln -s "${target_dir}" "${sid_dir}"' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to restore the ORACLE_SID alias for reused PVCs in ${RUNORACLE_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'rm -rf "${target_dir}"' "${RUNORACLE_FILE}"; then
  echo "FAIL: expected True Cache runOracle shim to clean incomplete db_unique_name storage before base startup in ${RUNORACLE_FILE}" >&2
  exit 1
fi

echo "PASS: createDBTrueCacheFlashbackWrapper23_26_test"
