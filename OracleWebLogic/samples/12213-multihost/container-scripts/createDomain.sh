#!/bin/bash
#
#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

if [ -z $ADMIN_PASSWORD ]; then
   # Auto generate Oracle WebLogic Server admin password
   while true; do
     s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 8 | head -n 1)
     if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
         break
     else
         echo "Password does not Match the criteria, re-generating..."
     fi
   done

   echo ""
   echo "    Oracle WebLogic Server Domain:"
   echo ""
   echo "      ----> 'weblogic' admin password: $s"
   echo ""
   ADMIN_PASSWORD=$s
else
   s=${ADMIN_PASSWORD}
   echo "      ----> 'weblogic' admin password: $s"
fi 

# Create domain
wlst.sh -skipWLSModuleScanning /u01/oracle/create-wls-domain.py
mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/ 
echo "username=${ADMIN_USERNAME}" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties 
echo "password=$s" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties 
echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc
# Deploy sample application
wlst.sh -skipWLSModuleScanning /u01/oracle/app-deploy.py
