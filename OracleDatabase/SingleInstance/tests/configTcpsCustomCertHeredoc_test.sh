#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: May, 2026
# Description: Regression test for custom-cert PKCS12 wallet import heredocs.
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

assert_custom_cert_import_heredoc() {
  local version="$1"
  local script_file="${REPO_ROOT}/dockerfiles/${version}/configTcps.sh"

  [ -f "${script_file}" ] || fail "missing configTcps.sh for ${version}"

  awk -v version="${version}" '
    /orapki wallet import_pkcs12/ && /<<EOF/ {
      found = 1
      in_import = 1
      next
    }

    in_import && /\$\{WALLET_PWD\}/ {
      wallet_pwd = 1
      next
    }

    in_import && /\$\{PKCS12_PWD\}/ {
      pkcs12_pwd = 1
      next
    }

    in_import && /^[[:space:]]*EOF$/ {
      if ($0 != "EOF") {
        printf "FAIL: %s custom-cert import_pkcs12 heredoc terminator must start at column 1; got line %d: %s\n", version, NR, $0 > "/dev/stderr"
        exit 1
      }
      if (!wallet_pwd || !pkcs12_pwd) {
        printf "FAIL: %s custom-cert import_pkcs12 heredoc is missing expected wallet or PKCS12 password input\n", version > "/dev/stderr"
        exit 1
      }
      closed = 1
      in_import = 0
      next
    }

    END {
      if (!found) {
        printf "FAIL: %s custom-cert import_pkcs12 heredoc was not found\n", version > "/dev/stderr"
        exit 1
      }
      if (!closed) {
        printf "FAIL: %s custom-cert import_pkcs12 heredoc was not closed\n", version > "/dev/stderr"
        exit 1
      }
    }
  ' "${script_file}" || exit 1
}

assert_custom_cert_import_heredoc "19.3.0"
assert_custom_cert_import_heredoc "23.26.0"
assert_custom_cert_import_heredoc "26.0.0"

echo "PASS: configTcpsCustomCertHeredoc_test"
