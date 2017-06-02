#!/bin/bash
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#

# Auto generate Oracle WebLogic Server admin password
ADMIN_PASSWORD=$(cat date| md5sum | fold -w 8 | head -n 1)

echo ""
echo "    Oracle WebLogic Server Auto Generated Empty Domain:"
echo ""
echo "      ----> 'weblogic' admin password: $ADMIN_PASSWORD"
echo ""

sed -i -e "s|ADMIN_PASSWORD|$ADMIN_PASSWORD|g" /u01/oracle/create-osb-domain.py

# Create an OSB compact domain
wlst.sh -skipWLSModuleScanning /u01/oracle/create-osb-domain.py
mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/
echo "username=weblogic" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
${DOMAIN_HOME}/bin/setDomainEnv.sh
