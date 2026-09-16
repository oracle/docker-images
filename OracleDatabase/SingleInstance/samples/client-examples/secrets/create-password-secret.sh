#!/usr/bin/env bash

set -euo pipefail

cleanup() {
    unset ORACLE_PASSWORD
}

trap cleanup EXIT

printf 'Database password: '
IFS= read -r -s ORACLE_PASSWORD
printf '%s' "$ORACLE_PASSWORD" | podman secret create oracle_pwd -
