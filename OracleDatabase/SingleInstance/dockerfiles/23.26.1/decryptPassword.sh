#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
# 
# Since: April, 2024
# Author: aditya.x.jain@oracle.com
# Description: Decrypt (if needed) and sets the password for sys, system and pdb_admin
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
SECRET_VOLUME="${SECRET_VOLUME:-/run/secrets}"
PASSWORD_FILE="${PASSWORD_FILE:-oracle_pwd}"
ORACLE_PWD_SECRET_FILE="${SECRET_VOLUME}/${PASSWORD_FILE}"
ORACLE_PWD_KEY_FILE="${SECRET_VOLUME}/oracle_pwd_privkey"

# Setting up ORACLE_PWD if podman secret is passed on
if [ -e "${ORACLE_PWD_SECRET_FILE}" ]; then
   # Decrypting ORACLE_PWD if private key is passed on as podman secret
   if [ -e "${ORACLE_PWD_KEY_FILE}" ]; then
      openssl pkeyutl -decrypt -in "${ORACLE_PWD_SECRET_FILE}" -out /var/tmp/oracle_pwd -inkey "${ORACLE_PWD_KEY_FILE}"
      echo "$(cat '/var/tmp/oracle_pwd')"
      rm -f /var/tmp/oracle_pwd
   else
      echo "$(cat "${ORACLE_PWD_SECRET_FILE}")"
   fi
   exit
elif [ -e "${ORACLE_PWD_KEY_FILE}" ]; then
   echo "Error: A secret for oracle_pwd_privkey has been detected but the corresponding ${PASSWORD_FILE} secret is missing. Existing…"
   exit 1;
fi

echo $ORACLE_PWD
