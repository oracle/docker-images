#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Guard the primary-host script contract for automatic True Cache service registration.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REGISTER_FILE="${REPO_ROOT}/extensions/truecache/registerService.sh"
SAMPLE_SCRIPT="${REPO_ROOT}/samples/truecache/configure-primary-truecache-service.sh"
EXTENSION_SCRIPT="${REPO_ROOT}/extensions/truecache/configure-primary-truecache-service.sh"
WRAPPER_FILE="${REPO_ROOT}/extensions/truecache/createDB.truecache-wrapper.sh"
DOCKERFILE_FILE="${REPO_ROOT}/extensions/truecache/Dockerfile"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -Fq 'PRIMARY_TC_SERVICE_SCRIPT_PATH=${PRIMARY_TC_SERVICE_SCRIPT_PATH:-"/home/oracle/configure-primary-truecache-service.sh"}' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to export the default PRIMARY_TC_SERVICE_SCRIPT_PATH"

grep -Fq 'PRIMARY_TC_SERVICE_CREDENTIAL_NAME=${PRIMARY_TC_SERVICE_CREDENTIAL_NAME:-""}' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to export the optional PRIMARY_TC_SERVICE_CREDENTIAL_NAME"

cmp -s "${SAMPLE_SCRIPT}" "${EXTENSION_SCRIPT}" \
  || fail "expected the extension-local primary-host helper copy to stay byte-identical to the sample script"

grep -Fq 'PRIMARY_TC_SERVICE_SCRIPT="configure-primary-truecache-service.sh"' "${DOCKERFILE_FILE}" \
  || fail "expected the truecache Dockerfile to name the prebaked primary-host helper"

grep -Fq 'COPY  --chown=oracle:dba $PRIMARY_TC_SERVICE_SCRIPT /home/oracle/configure-primary-truecache-service.sh' "${DOCKERFILE_FILE}" \
  || fail "expected the truecache Dockerfile to prebake the primary-host helper at the default path"

grep -Fq '"/home/oracle/configure-primary-truecache-service.sh"' "${DOCKERFILE_FILE}" \
  || fail "expected the truecache Dockerfile to mark the prebaked primary-host helper executable"

grep -Fq 'scheduler_script_path_sql=$(sqlEscapeLiteral "${PRIMARY_TC_SERVICE_SCRIPT_PATH}")' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to quote the configured primary-host helper path for DBMS_SCHEDULER"

grep -Fq "job_action  => '\${scheduler_script_path_sql}'" "${REGISTER_FILE}" \
  || fail "expected DBMS_SCHEDULER to execute the configured primary-host helper path directly"

grep -Fq 'connect_str=${PRIMARY_DB_CONNECT_STR}' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to submit the DBMS_SCHEDULER job through the primary CDB connect string so the helper can create the primary PDB service if needed"

grep -Fq 'number_of_arguments => 8' "${REGISTER_FILE}" \
  || fail "expected DBMS_SCHEDULER to pass the full primary-host script contract"

grep -Fq "argument_position => 1, argument_value => '\${primary_service_sql}'" "${REGISTER_FILE}" \
  || fail "expected DBMS_SCHEDULER to pass the primary service name as the first scheduler argument"

grep -Fq "dbms_scheduler.set_attribute(name => '\${job_name}', attribute => 'credential_name', value => '\${scheduler_credential_name_sql}');" "${REGISTER_FILE}" \
  || fail "expected registerService.sh to apply DBMS_SCHEDULER credential_name when PRIMARY_TC_SERVICE_CREDENTIAL_NAME is configured"

grep -Fq "AUTO_TC_SVC_REGISTRATION=false, so primary-side service creation, startup, and True Cache association are not automated." "${REGISTER_FILE}" \
  || fail "expected registerService.sh to explain the manual path when auto registration is disabled"

grep -Fq "'<PRIMARY_SYS_PASSWORD_OR_WALLET_SOURCE>'" "${REGISTER_FILE}" \
  || fail "expected registerService.sh to print the manual primary-host helper invocation with password-or-wallet source"

grep -Fq 'TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR' "${WRAPPER_FILE}" \
  || fail "expected createDB.truecache-wrapper.sh to support a mounted DB credentials wallet directory"

grep -Fq 'Using True Cache DB credentials wallet from ${WALLET_DIR} for DBCA primary authentication.' "${WRAPPER_FILE}" \
  || fail "expected createDB.truecache-wrapper.sh to log wallet-based DBCA authentication"

grep -Fq 'Using wallet-backed TNS_ADMIN=${TNS_ADMIN} for primary database connectivity.' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to configure wallet-backed primary SQL connectivity"

grep -Fq 'function getPrimaryCDBSQLOUTPUT {' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to expose a primary CDB SQL helper for association verification"

grep -Fq 'SELECT true_cache_service FROM v\$active_services WHERE upper(name)=' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to prefer v$active_services when verifying the primary True Cache association"

grep -Fq 'ORACLE_PWD is not set. Using dbCredentialsWallet for primary SQL connectivity.' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to retain wallet-backed primary SQL connectivity when ORACLE_PWD is unavailable"

if grep -Fq 'Loaded primary SYS password from mounted True Cache wallet secret file' "${REGISTER_FILE}"; then
  fail "registerService.sh should not source ORACLE_PWD from the mounted dbCredentialsWallet secret"
fi

if grep -Fq 'Loaded primary SYS password from mounted True Cache wallet secret file' "${WRAPPER_FILE}"; then
  fail "createDB.truecache-wrapper.sh should not source ORACLE_PWD from the mounted dbCredentialsWallet secret"
fi

grep -Fq 'password_source_sql=$(sqlEscapeLiteral "NO_PASSWORD")' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to support scheduler-driven registration without a password payload"

grep -Fq 'password_source_sql=$(sqlEscapeLiteral "WALLET_PATH:${PRIMARY_TC_SERVICE_WALLET_PATH}")' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to pass a primary-host wallet path when PRIMARY_TC_SERVICE_WALLET_PATH is configured"

grep -Fq '"${ORACLE_HOME}/bin/tnsping" "//${connect_target}"' "${REGISTER_FILE}" \
  || fail "expected registerService.sh to use tnsping for the local listener callback readiness check"

grep -Fq 'resolve_source_db()' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to choose the sourceDB locally"

grep -Fq 'resolve_local_instance_sid()' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to resolve ORACLE_SID for local SYSDBA connectivity"

grep -Fq 'resolve_dbca_path()' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to resolve the DBCA path dynamically"

grep -Fq 'This helper must run as ${EXPECTED_DB_OWNER}, but it started as ${CURRENT_OS_USER}.' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to fail fast when the scheduler starts it as the wrong OS user"

grep -Fq 'export PATH="${ORACLE_HOME}/bin:/usr/bin:/bin"' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to keep ORACLE_HOME first in PATH without prepending Grid binaries"

grep -Fq 'Sanitized PATH to keep only ORACLE_HOME runtime binaries first:' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to log the sanitized PATH"

grep -Fq 'Using ORACLE_SID ${ORACLE_SID} for local SYSDBA connectivity.' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to log the resolved ORACLE_SID"

grep -Fq "dbms_service.create_service('\${PRIMARY_SVCNAME}', '\${PRIMARY_SVCNAME}')" "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to create the primary service when needed"

grep -Fq "dbms_service.start_service('\${PRIMARY_SVCNAME}')" "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to start the primary service when needed"

grep -Fq 'resolve_wallet_path()' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to resolve a primary-host wallet path"

grep -Fq 'WALLET_PATH="$(resolve_wallet_path || true)"' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to prefer a mkstore wallet path when available"

grep -Fq -- '-useWalletForDBCredentials true' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to use DBCA wallet credential options when a wallet path is provided"

grep -Fq 'No PASSWORD_SOURCE or wallet path was provided. Running DBCA True Cache service configuration without stdin password.' "${SAMPLE_SCRIPT}" \
  || fail "expected sample primary-host script to support no-password and no-wallet invocation"

echo "PASS: truecachePrimaryServiceScriptPathContract_test"
