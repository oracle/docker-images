#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the 23.26 True Cache primary SQL*Plus connect-string builder.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REGISTER_FILE="${REPO_ROOT}/extensions/truecache/registerService.sh"

grep -Fq 'user="${PRIMARY_DB_USER%% as *}"' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to split PRIMARY_DB_USER before the privilege clause" >&2; exit 1; }

grep -Fq 'priv=" as ${PRIMARY_DB_USER#* as }"' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to preserve the full SQL*Plus privilege clause" >&2; exit 1; }

grep -Fq "printf '%s/%s@%s%s\\n' \"\${user}\" \"\${ORACLE_PWD}\" \"\${connect_target}\" \"\${priv}\"" "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to build password-based SQL*Plus connect strings without truncating the privilege clause" >&2; exit 1; }

grep -Fq "printf '/@%s%s\\n' \"\${connect_target}\" \"\${priv}\"" "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to build wallet-based SQL*Plus connect strings without truncating the privilege clause" >&2; exit 1; }

grep -Fq 'local primary_pdb_ezconnect_target="${PRIMARY_DB_HOST}:${PRIMARY_DB_PORT}/${primary_pdb_connect_target}"' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to use the full EZConnect target for primary PDB validation" >&2; exit 1; }

grep -Fq 'Using primary PDB connect target ${primary_pdb_ezconnect_target} for PDB ${PRIMARY_PDB_NAME}.' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to log the full primary PDB EZConnect target" >&2; exit 1; }

grep -Fq 'TRUE_CACHE_CALLBACK_SERVICE_NAME="${TRUEDB_UNIQUE_NAME}.${callback_domain}"' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to derive the external True Cache callback service from the primary connect-string domain" >&2; exit 1; }

grep -Fq 'Derived True Cache callback service ${TRUE_CACHE_CALLBACK_SERVICE_NAME} from primary connect string domain ${callback_domain}.' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to log the derived external True Cache callback service" >&2; exit 1; }

grep -Fq 'tc_service_name="${TRUE_CACHE_CALLBACK_SERVICE_NAME}"' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to use the external callback service for the primary-host helper connect string" >&2; exit 1; }

grep -Fq "printf '%s' \"PENDING_PRIMARY_UPDATE\"" "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to render a readable placeholder when the primary association metadata is not yet visible" >&2; exit 1; }

grep -Fq "normalized_state=\"READ_ONLY_TRANSITION_IN_PROGRESS\"" "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to label transient True Cache PDB open-mode churn without implying a hard communication failure" >&2; exit 1; }

grep -Fq 'final_association=[${association_output}] final_active=[${active_output}]' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to log the final observed association and active values on success" >&2; exit 1; }

if grep -Fq 'delFile() : fname=' "${REGISTER_FILE}"; then
  echo "FAIL: expected registerService.sh to keep temporary file deletion silent during normal runs" >&2
  exit 1
fi

grep -Fq 'export TRUECACHE_ASSOCIATION_LOG_INTERVAL_SECONDS=${TRUECACHE_ASSOCIATION_LOG_INTERVAL_SECONDS:-60}' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to expose a tunable primary-association log interval" >&2; exit 1; }

grep -Fq 'next_log_elapsed=$((elapsed + log_interval_seconds))' "${REGISTER_FILE}" \
  || { echo "FAIL: expected registerService.sh to rate-limit primary association progress logs independently of the polling interval" >&2; exit 1; }

echo "PASS: registerServicePrimaryConnectStr23_26_test"
