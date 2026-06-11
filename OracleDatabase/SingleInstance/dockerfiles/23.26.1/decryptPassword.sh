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

# Setting up ORACLE_PWD if podman secret is passed on
if [ -e '/run/secrets/oracle_pwd' ]; then
   # Decrypting ORACLE_PWD if private key is passed on as podman secret
   if [ -e '/run/secrets/oracle_pwd_privkey' ]; then
      openssl pkeyutl -decrypt -in /run/secrets/oracle_pwd -out /var/tmp/oracle_pwd -inkey /run/secrets/oracle_pwd_privkey
      echo "$(cat '/var/tmp/oracle_pwd')"
      rm -f /var/tmp/oracle_pwd
   else
      echo "$(cat '/run/secrets/oracle_pwd')"
   fi
   exit
elif [ -e '/run/secrets/oracle_pwd_privkey' ]; then
   echo "Error: A secret for oracle_pwd_privkey has been detected but the corresponding oracle_pwd secret is missing. Existing…"
   exit 1;
fi

echo $ORACLE_PWD
