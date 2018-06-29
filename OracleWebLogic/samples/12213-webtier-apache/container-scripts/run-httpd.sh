#!/bin/bash
#
# Since: May, 2018
# Author: dongbo.xiao@oracle.com
# Description: script to start Apache HTTP Server 
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

# Apache gets grumpy about PID files pre-existing
rm -f /run/httpd/httpd.pid

echo $SSL_CERT_PATH $SSL_CERT_NAME $VIRTUAL_HOST_NAME $GENERATE_CERT_IF_ABSENT

if [ ! -f /config/custom_mod_wl_apache.conf ]; then
  cp /configtmp/custom_mod_wl_apache.conf /config/
fi

# In order to enable SSL from USER to Apache HTTP Server, the `VIRTUAL_HOST_NAME`
# environment variable needs to be specified. If it is not set, SSL is not enabled.
if [ -z ${VIRTUAL_HOST_NAME} ]; then 
  echo VIRTUAL_HOST_NAME environment variable is not set, and therefore SSL is not enabled.
else 
  # Set up SSL
  use_example=false
  if [ -z ${SSL_CERT_PATH} ]; then
    export SSL_CERT_PATH=/config/ssl
    if [ -z ${SSL_CERT_NAME} ]; then
      export SSL_CERT_NAME=example
      use_example=true
    fi 
  else 
    if [ -z ${SSL_CERT_NAME} ]; then
      export SSL_CERT_NAME=example
    fi
  fi

  export SSL_CERT_FILE=$SSL_CERT_PATH/$SSL_CERT_NAME.crt
  export SSL_CERT_KEY_FILE=$SSL_CERT_PATH/$SSL_CERT_NAME.key

  if [ ${use_example} = "false" ] ||
     [ ${GENERATE_CERT_IF_ABSENT} = "true" ]; then

    # We only copy this file when SSL is enabled
    cp /configtmp/custom_mod_ssl_apache.conf /etc/httpd/conf.d/
  fi

  if [ ! -f ${SSL_CERT_FILE} ] || [ ! -f ${SSL_CERT_KEY_FILE} ]; then
    if [ ${GENERATE_CERT_IF_ABSENT} = "true" ]; then
      echo Generating self-signed certificates
      if [ ! -d $SSL_CERT_PATH ]; then
        mkdir -p 777 ${SSL_CERT_PATH} 
      fi
      sh /u01/oracle/container-scripts/certgen.sh
    else 
      echo The certificate and key files do not exist, and GENERATE_CERT_IF_ABSENT is set to false. No certificate is generated. 
    fi
  else
    echo Found required SSL certificate and key
  fi
fi

exec httpd -DFOREGROUND
