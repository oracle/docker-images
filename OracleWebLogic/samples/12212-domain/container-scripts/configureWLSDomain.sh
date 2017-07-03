#!/bin/bash

if [ -z $ADMIN_PASSWORD ]; then
	# Auto generate Oracle WebLogic Server admin password
	echo 'Admin Password is not specified, generating ...'
	while true; do
		s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 8 | head -n 1)
		if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
			ADMIN_PASSWORD=$s
			break
		else
			echo "!Password does not Match the criteria, re-generating..."
		fi
	done
fi

echo ""
echo "      ----> 'weblogic' admin password: ${ADMIN_PASSWORD}"
echo ""

/u01/oracle/wlst /u01/oracle/create-wls-domain.py
mkdir -p /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security
echo "username=weblogic" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
echo ". /u01/oracle/user_projects/domains/$DOMAIN_NAME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc
