#!/bin/sh
# Generated configuration file
CONFIG_FILE="config.txt"

cat > $CONFIG_FILE <<-EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions=v3_req
extensions=v3_req
distinguished_name = dn

[dn]
C = US
ST = CA 
L = Redwood Shores
O = Oracle Corporation
OU = Apache HTTP Server With Plugin 
CN = $VIRTUAL_HOST_NAME

[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.$VIRTUAL_HOST_NAME
DNS.2 = localhost
EOF

echo "Generating certs for $VIRTUAL_HOST_NAME"

# Generate our Private Key, CSR and Certificate
# Use SHA-2 as SHA-1 is unsupported from Jan 1, 2017

openssl req -x509 -newkey rsa:2048 -sha256 -nodes -keyout "$SSL_CERT_KEY_FILE"  -days 3650 -out "$SSL_CERT_FILE" -config "$CONFIG_FILE"

# OPTIONAL - write an info to see the details of the generated crt
openssl x509 -noout -fingerprint -text < "$SSL_CERT_FILE" > "$SSL_CERT_FILE.info"
# Protect the key
chmod 400 "$SSL_CERT_KEY_FILE"
