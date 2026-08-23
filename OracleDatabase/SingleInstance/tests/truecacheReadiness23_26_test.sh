#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: April, 2026
# Description: Regression tests for 23.26 true cache readiness handling in runOracle.sh.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNORACLE_FILE="${REPO_ROOT}/dockerfiles/23.26.0/runOracle.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [ "${expected}" != "${actual}" ]; then
    fail "${message}: expected='${expected}' actual='${actual}'"
  fi
}

setup_test_env() {
  TEST_TMPDIR="$(mktemp -d)"
  export TEST_TMPDIR
  export TEST_STATE_FILE="${TEST_TMPDIR}/db_state"
  export TEST_SQLPLUS_LOG="${TEST_TMPDIR}/sqlplus.log"
  export TEST_SQLPLUS_MODE="${1}"

  mkdir -p "${TEST_TMPDIR}/bin"

  cat > "${TEST_TMPDIR}/bin/sqlplus" <<'EOF'
#!/bin/bash
set -euo pipefail

input="$(cat)"
printf '%s\n--SQL--\n%s\n' "$*" "$input" >> "${TEST_SQLPLUS_LOG}"

if [[ "${input}" == *"SELECT database_role || '|' || open_mode FROM v\$database;"* ]]; then
  printf 'TRUE CACHE|%s\n' "$(cat "${TEST_STATE_FILE}")"
  exit 0
fi

if [[ "${input}" == *"ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION"* ]]; then
  if [ "${TEST_SQLPLUS_MODE}" = "flashback_error" ]; then
    echo "ORA-61851: simulated flashback failure" >&2
    exit 1
  fi
  case "$(cat "${TEST_STATE_FILE}")" in
    MOUNTED|READ\ ONLY)
      printf 'READ ONLY WITH APPLY\n' > "${TEST_STATE_FILE}"
      ;;
  esac
  exit 0
fi

exit 0
EOF
  chmod +x "${TEST_TMPDIR}/bin/sqlplus"

  cat > "${TEST_TMPDIR}/check_db.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

case "$(cat "${TEST_STATE_FILE}")" in
  "READ ONLY WITH APPLY")
    exit 0
    ;;
  "MOUNTED"|"READ ONLY")
    exit 5
    ;;
  *)
    exit 2
    ;;
esac
EOF
  chmod +x "${TEST_TMPDIR}/check_db.sh"

  export PATH="${TEST_TMPDIR}/bin:${PATH}"
  export ORACLE_BASE="${TEST_TMPDIR}"
  export CHECK_DB_FILE="check_db.sh"
  export DB_STATUS_CHECK_BACKOFFS="1 1 1"
  export DB_READY_TIMEOUT_SECONDS=3
  export TRUE_CACHE=true
  export RUNORACLE_UNIT_TEST_MODE=true
}

teardown_test_env() {
  rm -rf "${TEST_TMPDIR}"
}

run_wait_for_database_ready() {
  # shellcheck disable=SC1090
  source "${RUNORACLE_FILE}"
  sleep() { :; }
  set +e
  wait_for_database_ready
  return $?
}

test_transitions_mounted_to_apply() {
  setup_test_env mounted
  printf 'MOUNTED\n' > "${TEST_STATE_FILE}"

  run_wait_for_database_ready
  rc=$?

  final_state="$(cat "${TEST_STATE_FILE}")"
  assert_eq "0" "${rc}" "wait_for_database_ready should succeed from MOUNTED"
  assert_eq "READ ONLY WITH APPLY" "${final_state}" "true cache state should reach apply mode"
  teardown_test_env
}

test_transitions_read_only_to_apply() {
  setup_test_env readonly
  printf 'READ ONLY\n' > "${TEST_STATE_FILE}"

  run_wait_for_database_ready
  rc=$?

  final_state="$(cat "${TEST_STATE_FILE}")"
  assert_eq "0" "${rc}" "wait_for_database_ready should succeed from READ ONLY"
  assert_eq "READ ONLY WITH APPLY" "${final_state}" "read only true cache should start apply"
  teardown_test_env
}

test_invalid_state_fails_fast() {
  setup_test_env invalid
  printf 'READ WRITE\n' > "${TEST_STATE_FILE}"

  set +e
  run_wait_for_database_ready
  rc=$?
  set -e
  if [ "${rc}" -eq 0 ]; then
    fail "wait_for_database_ready unexpectedly succeeded from invalid state"
  fi

  assert_eq "2" "${rc}" "invalid true cache state should return failure"
  teardown_test_env
}

test_flashback_style_sql_failure_times_out() {
  setup_test_env flashback_error
  printf 'READ ONLY\n' > "${TEST_STATE_FILE}"

  set +e
  run_wait_for_database_ready
  rc=$?
  set -e

  if [ "${rc}" -eq 0 ]; then
    fail "wait_for_database_ready unexpectedly succeeded after simulated SQL failure"
  fi

  sql_log="$(cat "${TEST_SQLPLUS_LOG}")"
  case "${sql_log}" in
    *"ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION"*) ;;
    *)
      fail "expected recovery command to be attempted during simulated SQL failure"
      ;;
  esac

  assert_eq "5" "${rc}" "flashback-style SQL failure should leave readiness unresolved"
  teardown_test_env
}

test_transitions_mounted_to_apply
test_transitions_read_only_to_apply
test_invalid_state_fails_fast
test_flashback_style_sql_failure_times_out

echo "PASS: truecacheReadiness23_26_test"
