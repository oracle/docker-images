#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26 True Cache wallet-only DBCA shim and RAC metadata pinning path.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"

if ! grep -Fq 'Skipping RAC primary metadata pinning because neither ORACLE_PWD nor dbCredentialsWallet is available.' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to explain the wallet-only RAC metadata fallback in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'connect_str=$(build_true_cache_primary_connect_str "${PRIMARY_DB_CONN_STR}")' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to use wallet-capable primary metadata connects in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'instance_connect_str=$(build_true_cache_primary_connect_str "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${local_host})(PORT=${local_port}))(CONNECT_DATA=(SERVICE_NAME=${service_name})(INSTANCE_NAME=${instance_name})))")' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to use wallet-capable instance-specific RAC connects in ${WRAPPER_FILE}" >&2
  exit 1
fi

if ! grep -Fq 'Removed legacy empty remote SYS password line from True Cache DBCA stdin because wallet-only auth is enabled.' "${WRAPPER_FILE}"; then
  echo "FAIL: expected True Cache wrapper to normalize DBCA stdin for wallet-only plus TDE mode in ${WRAPPER_FILE}" >&2
  exit 1
fi

echo "PASS: createDBTrueCacheWalletOnlyShim23_26_test"
