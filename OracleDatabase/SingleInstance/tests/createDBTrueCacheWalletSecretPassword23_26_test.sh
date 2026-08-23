#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26 True Cache wallet-directory DBCA auth contract.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"

grep -Fq 'TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR' "${WRAPPER_FILE}" \
  || { echo "FAIL: expected True Cache wrapper to support a mounted True Cache DB credentials wallet directory" >&2; exit 1; }

grep -Fq 'Using True Cache DB credentials wallet from ${WALLET_DIR} for DBCA primary authentication.' "${WRAPPER_FILE}" \
  || { echo "FAIL: expected True Cache wrapper to prefer mounted wallet-directory auth for DBCA when present" >&2; exit 1; }

if grep -Fq 'Loaded primary SYS password from mounted True Cache wallet secret file' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to avoid the removed wallet-secret password-file bridge" >&2
  exit 1
fi

grep -Fq 'set -- "$@" -sourceTdeWalletPassword "${TDE_WALLET_PWD}"' "${WRAPPER_FILE}" \
  || { echo "FAIL: expected True Cache wrapper to pass the source TDE wallet password as an explicit DBCA argument" >&2; exit 1; }

grep -Fq 'Removed legacy TDE wallet password stdin line because -sourceTdeWalletPassword is enabled.' "${WRAPPER_FILE}" \
  || { echo "FAIL: expected True Cache wrapper to strip the old TDE stdin line once sourceTdeWalletPassword is used" >&2; exit 1; }

echo "PASS: createDBTrueCacheWalletSecretPassword23_26_test"
