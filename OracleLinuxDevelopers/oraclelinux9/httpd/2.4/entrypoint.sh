#!/bin/bash

set -eu pipefail

SERVER_CERT="$CERTIFICATE_DIR/fullchain.pem"
SERVER_KEY="$KEY_DIR/privkey.pem"

if [ ! -f "$SERVER_KEY" ]; then
    echo "Generating certificate private key for SSL support" 1>&2
    openssl genpkey -algorithm RSA -out "$SERVER_KEY" 1>&2
fi

if [ ! -f "$SERVER_CERT" ]; then
    echo "Generating self-signed certificate for SSL support" 1>&2
    openssl req -x509 -new -nodes -key "$SERVER_KEY" -sha256 -days 3650 -out "$SERVER_CERT" -subj "/C=US/ST=California/L=San Francisco/O=Test Company/CN=localhost" 1>&2
fi

httpd -DFOREGROUND