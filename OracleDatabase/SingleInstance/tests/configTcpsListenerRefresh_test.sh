#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Regression test for listener refresh after TCPS wallet updates.
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

assert_listener_refresh_tracks_wallet_changes() {
  local version="$1"
  local script_file="${REPO_ROOT}/dockerfiles/${version}/configTcps.sh"

  [ -f "${script_file}" ] || fail "missing configTcps.sh for ${version}"

  awk -v version="${version}" '
    /TCPS_WALLET_CHANGED=0/ {
      initialized = 1
    }

    /TCPS_WALLET_CHANGED=1/ {
      wallet_changed = 1
    }

    /^if / && /TCPS_NET_CHANGED/ && /TCPS_WALLET_CHANGED/ && /\|\|/ {
      listener_gate = 1
    }

    /reconfigure_listener/ && listener_gate {
      listener_reconfigured = 1
    }

    END {
      if (!initialized) {
        printf "FAIL: %s does not initialize TCPS_WALLET_CHANGED\n", version > "/dev/stderr"
        exit 1
      }
      if (!wallet_changed) {
        printf "FAIL: %s does not mark server wallet material as changed\n", version > "/dev/stderr"
        exit 1
      }
      if (!listener_reconfigured) {
        printf "FAIL: %s listener reconfiguration is not gated on wallet changes\n", version > "/dev/stderr"
        exit 1
      }
    }
  ' "${script_file}" || exit 1
}

assert_listener_refresh_tracks_wallet_changes "19.3.0"
assert_listener_refresh_tracks_wallet_changes "23.26.0"
assert_listener_refresh_tracks_wallet_changes "26.0.0"

echo "PASS: configTcpsListenerRefresh_test"
