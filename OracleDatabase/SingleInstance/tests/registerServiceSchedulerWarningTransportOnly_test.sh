#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the transport-only path when scheduler execution failed.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REGISTER_FILE="${REPO_ROOT}/extensions/truecache/registerService.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -Fq 'print_message "${DEFERRED_PRIMARY_SCHEDULER_WARNING}"' "${REGISTER_FILE}" \
  || fail "expected transport-only scheduler warning path to surface the deferred scheduler failure"

grep -Fq 'Primary-side service registration did not complete. True Cache transport is active, but the primary association metadata is still empty.' "${REGISTER_FILE}" \
  || fail "expected transport-only scheduler warning path to explain that association is still missing"

if grep -Fq 'Primary-side registration completed despite earlier scheduler noise.' "${REGISTER_FILE}"; then
  matches=$(grep -Fn 'Primary-side registration completed despite earlier scheduler noise.' "${REGISTER_FILE}" | wc -l)
  [ "${matches}" -eq 1 ] || fail "expected only the associated-service success path to use the earlier scheduler-noise completion message"
fi

echo "PASS: registerServiceSchedulerWarningTransportOnly_test"
