#!/bin/bash
## Copyright (c) 2021, Oracle and/or its affiliates.
set -e

: "${NGINX_CRT:?}"
: "${NGINX_KEY:?}"

##
##  c r e a t e _ c e r t i f i c a t e
##  Create a self-signed certificate/key pair
##
function create_certificate() {
    local config
    config="$(mktemp)"
    cat<<EOF > "${config}"
[req]
distinguished_name = distinguished_name
x509_extensions    = x509_extensions
prompt             = no

[distinguished_name]
CN                 = GoldenGate Deployment

[x509_extensions]
extendedKeyUsage   = serverAuth
EOF
    mkdir -p "$(dirname "${NGINX_CRT}")"
    openssl req -x509 -sha256                              \
            -newkey rsa:2048 -nodes -keyout "${NGINX_KEY}"  \
            -days $((365 * 3))      -out    "${NGINX_CRT}" \
            -config "${config}"
    rm "${config}"
}

create_certificate
