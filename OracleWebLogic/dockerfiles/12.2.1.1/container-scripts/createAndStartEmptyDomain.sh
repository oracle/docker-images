#!/bin/bash
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# Auto generate ORACLE PWD
ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc '0-9A-Z' | fold -w 8 | head -n 1)
echo "ORACLE AUTO GENERATED ADMIN PASSWORD:" $ADMIN_PASSWORD


sed -i -e "s|ADMIN_PASSWORD|$ADMIN_PASSWORD|g" /u01/oracle/create-wls-domain.py

# Create the empty domain
wlst.sh /u01/oracle/create-wls-domain.py
mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/ 
echo "username=weblogic" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties 
echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties 
${DOMAIN_HOME}/bin/setDomainEnv.sh 

#Start Admin Server and tail the logs

${DOMAIN_HOME}/startWebLogic.sh
touch ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log
tail -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log



