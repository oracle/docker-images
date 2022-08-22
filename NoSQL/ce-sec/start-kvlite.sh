#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -e

java -jar lib/kvstore.jar kvlite -secure-config enable -root /kvroot -host "$HOSTNAME" -port "$KV_PORT" -admin-web-port "$KV_ADMIN_PORT" -harange "${KV_HARANGE/\-/,}" -servicerange "${KV_SERVICERANGE/\-/,}" -storagedirsizegb ${KV_STORAGESIZE-10} &
while java -jar lib/kvstore.jar ping -host $HOSTNAME -port $KV_PORT -security /kvroot/security/user.security  >/dev/null 2>&1 ; [ $? -ne 0 ];do
    echo "Waiting for kvstore to start..."
    sleep 1
done
./sec/setup-http-proxy-sec.sh
java -jar lib/httpproxy.jar -helperHosts "$HOSTNAME:$KV_PORT" -storeName kvstore -httpsPort "$KV_PROXY_PORT" -storeSecurityFile /kvroot/proxy/proxy.login -sslCertificate /kvroot/proxy/certificate.pem -sslPrivateKey /kvroot/proxy/key-pkcs8.pem -sslPrivateKeyPass $(cat < <(cat /kvroot/proxy/pwdin))  -verbose true
