#!/bin/sh
set -e

# Apache gets grumpy about PID files pre-existing
rm -f /run/httpd/httpd.pid

echo $SSL_CERT_FILE $SSL_CERT_KEY_FILE $VIRTUAL_HOST_NAME
if [ ! "$(ls -A /config)" ]; then
  cp -rf /configtmp/* /config/
fi

# In order to enable SSL from USER to Apache HTTP Server, VIRTUAL_HOST_NAME
# environment variable needs to be specified. If it is not set, SSL is disabled
# is used. 
if [ -z ${VIRTUAL_HOST_NAME} ]; then
  echo VIRTUAL_HOST_NAME is not specified, so SSL is disabled
else 
  # Set up SSL
  cp /config/custom_mod_ssl_apache.conf.sample /etc/httpd/conf.d/custom_mod_ssl_apache.conf

  if [ ! -z ${SSL_CERT_FILE} ] && [ ! -z ${SSL_CERT_KEY_FILE} ]; then
    if [ ! -f ${SSL_CERT_FILE} ] || [ ! -f ${SSL_CERT_KEY_FILE} ]; then
      if [ ${GENERATE_CERT_IF_ABSENT} = "true" ]; then
        echo Generating a new self-signed certificate
        sh /u01/oracle/container-scripts/certgen.sh
      else 
        echo The certificate and key files do not exist, and GENERATE_CERT_IF_ABSENT is set to false. No certificate will be generated. 
      fi
    else
      echo Found required SSL certificate and key
    fi
  else
    echo SSL_CERT_FILE and SSL_CERT_KEY_FILE are not set, use the built-in example certificate. This should only be used as a demo or for testing purposes.
    export SSL_CERT_FILE="/config/ssl/example.crt"
    export SSL_CERT_KEY_FILE="/config/ssl/example.key"
  fi
fi

ls /config/ssl/*

exec httpd -DFOREGROUND
