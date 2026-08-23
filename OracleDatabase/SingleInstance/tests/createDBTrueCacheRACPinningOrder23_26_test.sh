#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26 True Cache RAC metadata pinning call order.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"

load_line=$(grep -n '^load_true_cache_primary_sys_password_from_wallet_secret$' "${WRAPPER_FILE}" | tail -n1 | cut -d: -f1)
pin_line=$(grep -n '^pin_primary_connect_string_for_rac$' "${WRAPPER_FILE}" | tail -n1 | cut -d: -f1)

if [ -z "${load_line}" ] || [ -z "${pin_line}" ]; then
  echo "FAIL: expected wrapper main flow to call both load_true_cache_primary_sys_password_from_wallet_secret and pin_primary_connect_string_for_rac" >&2
  exit 1
fi

if [ "${load_line}" -ge "${pin_line}" ]; then
  echo "FAIL: expected wrapper to load ORACLE_PWD from the mounted wallet secret before pin_primary_connect_string_for_rac" >&2
  exit 1
fi

echo "PASS: createDBTrueCacheRACPinningOrder23_26_test"
