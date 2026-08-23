#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: April, 2026
# Description: Regression test for preserving a caller-provided True Cache blob path.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETUP_FILE="${REPO_ROOT}/extensions/truecache/setup.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

TEST_TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TEST_TMPDIR}"
}
trap cleanup EXIT

export ORACLE_BASE="${TEST_TMPDIR}/oracle_base"
export ORACLE_HOME="${TEST_TMPDIR}/oracle_home"
export ORACLE_SID="ORCLTC"
export CHECKPOINT_FILE_EXTN=".created"
export PDB_TC_SVCS="APPPDB1:tpdb_primary:tpdb_cache"
export PRIMARY_DB_CONN_STR="10.0.2.106:1521/primary_service"
export PRIMARY_DB_NAME="ORCLPRD"
export DECRYPT_PWD_FILE="decryptPassword.sh"
export TRUE_CACHE_BLOB="${TEST_TMPDIR}/stage/tc_config_blob.tar.gz"
export LOGDIR="${TEST_TMPDIR}/logs"

mkdir -p "${ORACLE_BASE}/oradata" "${ORACLE_HOME}" "${TEST_TMPDIR}/stage" "${LOGDIR}"
touch "${TRUE_CACHE_BLOB}"

cat > "${ORACLE_BASE}/${DECRYPT_PWD_FILE}" <<'EOF'
#!/bin/bash
printf 'SecretPwd1'
EOF
chmod +x "${ORACLE_BASE}/${DECRYPT_PWD_FILE}"

actual_output="$("${SETUP_FILE}")"

if [ "${actual_output}" != "${TRUE_CACHE_BLOB}" ]; then
  fail "setup.sh should emit the provided blob path; expected='${TRUE_CACHE_BLOB}' actual='${actual_output}'"
fi

touch "${ORACLE_BASE}/oradata/.${ORACLE_SID}${CHECKPOINT_FILE_EXTN}"

actual_output="$("${SETUP_FILE}")"

if [ "${actual_output}" != "${TRUE_CACHE_BLOB}" ]; then
  fail "setup.sh should preserve the provided blob path after restart; expected='${TRUE_CACHE_BLOB}' actual='${actual_output}'"
fi

echo "PASS: truecacheBlobPathPreservation_test"
