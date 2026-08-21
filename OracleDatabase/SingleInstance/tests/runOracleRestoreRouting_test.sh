#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Regression test for backup restore routing in runOracle.sh.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_restore_route_accepts_object_or_filesystem() {
  local version="$1"
  local script_file="${REPO_ROOT}/dockerfiles/${version}/runOracle.sh"

  [ -f "${script_file}" ] || fail "missing runOracle.sh for ${version}"

  awk -v version="${version}" '
    /CLONE_DB_FROM_OBJ_BACKUP/ && /CLONE_DB_FROM_FS_BACKUP/ {
      if ($0 !~ /run_or_debug/ && $0 !~ /\|\|/) {
        next
      }
      if ($0 !~ /CLONE_DB_FROM_OBJ_BACKUP:-/ || $0 !~ /CLONE_DB_FROM_FS_BACKUP:-/) {
        printf "FAIL: %s restore route should use guarded object and filesystem backup checks; got line %d: %s\n", version, NR, $0 > "/dev/stderr"
        exit 1
      }
      found_route = 1
      next
    }

    found_route && /run_or_debug "cloneDBObjBkup\.sh"/ {
      found_clone_call = 1
    }

    found_route && /run_or_debug "createDB\.sh"/ && !found_clone_call {
      printf "FAIL: %s createDB route appears before cloneDBObjBkup route after restore condition\n", version > "/dev/stderr"
      exit 1
    }

    END {
      if (!found_route) {
        printf "FAIL: %s runOracle.sh does not route both object-store and filesystem restore requests\n", version > "/dev/stderr"
        exit 1
      }
      if (!found_clone_call) {
        printf "FAIL: %s restore route does not invoke cloneDBObjBkup.sh\n", version > "/dev/stderr"
        exit 1
      }
    }
  ' "${script_file}" || exit 1
}

assert_restore_route_accepts_object_or_filesystem "19.3.0"
assert_restore_route_accepts_object_or_filesystem "23.26.0"
assert_restore_route_accepts_object_or_filesystem "26.0.0"

echo "PASS: runOracleRestoreRouting_test"
