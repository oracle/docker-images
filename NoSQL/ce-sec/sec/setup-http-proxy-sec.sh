# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#

if [ -d /kvroot/proxy/ ] ; then
  echo "Reusing existing configuration"
  exit 0;
fi

mkdir -p /kvroot/proxy/

echo "Creating USER proxy_user"

java -jar lib/sql.jar -helper-hosts localhost:5000 -store kvstore -security /kvroot/security/user.security <<EOF
CREATE USER proxy_user IDENTIFIED BY "${KV_PROXY_PWD-ProxyPass@@123}";
EOF


echo "Creating proxy secfiles"

java -jar lib/kvstore.jar securityconfig pwdfile create -file /kvroot/proxy/proxy.passwd
java -jar lib/kvstore.jar securityconfig pwdfile secret -file /kvroot/proxy/proxy.passwd -set -alias proxy_user -secret "${KV_PROXY_PWD-ProxyPass@@123}"
cp /kvroot/security/client.trust /kvroot/proxy/client.trust
cp /kvroot/security/client.security /kvroot/proxy/proxy.login
cp sec/proxy.login /kvroot/proxy/proxy.login
echo "oracle.kv.auth.username=proxy_user" >> /kvroot/proxy/proxy.login
echo "oracle.kv.auth.pwdfile.file=proxy.passwd" >> /kvroot/proxy/proxy.login

echo "Creating password"
openssl rand -out sec/pwd -base64 14
cp sec/pwd /kvroot/proxy/pwdin
cp sec/pwd /kvroot/proxy/pwdout

echo "Creating certificate"
openssl req -x509 -days 365 -newkey rsa:4096 -keyout /kvroot/proxy/key.pem -out /kvroot/proxy/certificate.pem -subj "/CN=${HOSTNAME}" -passin file:/kvroot/proxy/pwdin -passout file:/kvroot/proxy/pwdout
openssl pkcs8 -topk8 -inform PEM -outform PEM -in /kvroot/proxy/key.pem -out /kvroot/proxy/key-pkcs8.pem -passin file:/kvroot/proxy/pwdin -passout file:/kvroot/proxy/pwdout  -v1 PBE-SHA1-3DES
keytool -import -alias example -keystore /kvroot/proxy/driver.trust -file /kvroot/proxy/certificate.pem  -storepass file:/kvroot/proxy/pwdin -noprompt


if [ ! -z "${KV_DRIVER_USER_PWD}" ] ; then
  echo "Creating USER proxy_user and driver_user"
  java -jar lib/sql.jar -helper-hosts localhost:5000 -store kvstore -security /kvroot/security/user.security <<EOF
CREATE USER driver_user IDENTIFIED BY "${KV_DRIVER_USER_PWD}";
GRANT READWRITE TO USER driver_user;
GRANT DBADMIN TO USER driver_user;
EOF
fi

if [ -d /shared_conf ]; then
  cp /kvroot/security/client.trust /shared_conf
  cp /kvroot/security/user.security /shared_conf
  cp /kvroot/security/user.passwd /shared_conf
  cp /kvroot/proxy/certificate.pem /shared_conf
  cp /kvroot/proxy/driver.trust  /shared_conf
fi
