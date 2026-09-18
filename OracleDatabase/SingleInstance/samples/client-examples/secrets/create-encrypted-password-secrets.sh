#!/usr/bin/env bash

set -euo pipefail

secret_dir="$(mktemp -d "${TMPDIR:-/tmp}/oracle-free-secrets.XXXXXX")"

cleanup() {
    unset ORACLE_PASSWORD
    rm -f \
        "$secret_dir/pwdfile.txt" \
        "$secret_dir/pwdfile.enc" \
        "$secret_dir/key.pem" \
        "$secret_dir/key.pub"
    rmdir "$secret_dir" 2>/dev/null || true
}

trap cleanup EXIT
umask 077

printf 'Database password: '
IFS= read -r -s ORACLE_PASSWORD
printf '%s' "$ORACLE_PASSWORD" > "$secret_dir/pwdfile.txt"
unset ORACLE_PASSWORD

openssl genrsa -out "$secret_dir/key.pem" 2048
openssl rsa -in "$secret_dir/key.pem" \
    -out "$secret_dir/key.pub" -pubout
openssl pkeyutl -encrypt \
    -in "$secret_dir/pwdfile.txt" \
    -out "$secret_dir/pwdfile.enc" \
    -pubin -inkey "$secret_dir/key.pub"
rm -f "$secret_dir/pwdfile.txt"

podman secret create oracle_pwd "$secret_dir/pwdfile.enc"
podman secret create oracle_pwd_privkey "$secret_dir/key.pem"
