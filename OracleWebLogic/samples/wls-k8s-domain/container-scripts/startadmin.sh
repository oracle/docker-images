#!/bin/bash

#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start the WebLogic Admin Server
echo "current user: `whoami`"
. $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh

echo "DOMAIN_NAME=$DOMAIN_NAME, SAMPLE_DOMAIN_HOME=$SAMPLE_DOMAIN_HOME"
echo "CLASSPATH=$CLASSPATH"

function setupDomain {
	mkdir -p $SAMPLE_DOMAIN_HOME/servers/AdminServer/security && \
	echo "username=$WLUSER" > $SAMPLE_DOMAIN_HOME/servers/AdminServer/security/boot.identity && \
	echo "password=$WLPASSWORD" >> $SAMPLE_DOMAIN_HOME/servers/AdminServer/security/boot.identity
	# start admin server
	echo "starting admin server..."
	cd $SAMPLE_DOMAIN_HOME
        echo y | java -Xms256m -Xmx512m -Dweblogic.ListenPort=$ADMIN_PORT  -Dweblogic.management.username=$WLUSER \
        -Dweblogic.management.password=$WLPASSWORD -Dweblogic.Domain=$DOMAIN_NAME -Dweblogic.Name=AdminServer \
         weblogic.Server 1>&2 >admin.out &

	# create domain resources
	cd $ORACLE_HOME
	python run.py createDomain
} 

# domain provision
configDir="$SAMPLE_DOMAIN_HOME/config"
if [ -d "$configDir" ]
then
	echo "Domain provisioning is already done. starting admin server ..."
	nohup $SAMPLE_DOMAIN_HOME/bin/startWebLogic.sh 1>&2 >admin.out &
else
	setupDomain
fi

tail -f /u01/wlsdomain/admin.out

