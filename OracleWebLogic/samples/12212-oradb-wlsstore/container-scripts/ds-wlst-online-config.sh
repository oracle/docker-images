#! /bin/bash
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

#Loop determining state of WLS
function check_wls {
    action=$1
    host=$2
    admin_port=$3
    sleeptime=$4
    while true
    do
        sleep $sleeptime
        if [ "$action" == "started" ]; then
            started_url="http://$host:$admin_port/weblogic/ready"
            echo -e "[Provisioning Script] Waiting for WebLogic server to get $action, checking $started_url"
            status=`/usr/bin/curl -s -i $started_url | grep "200 OK"`
            echo "[Provisioning Script] Status:" $status
            if [ ! -z "$status" ]; then
              break
            fi
        elif [ "$action" == "shutdown" ]; then
            shutdown_url="http://$host:$admin_port"
            echo -e "[Provisioning Script] Waiting for WebLogic server to get $action, checking $shutdown_url"
            status=`/usr/bin/curl -s -i $shutdown_url | grep "500 Can't connect"`
            if [ ! -z "$status" ]; then
              break
            fi
        fi
    done
    echo -e "[Provisioning Script] WebLogic Server has $action"
}



#echo 'Setting environment variable for username and password '

ADMIN_PASSWORD="welcome1"
ADMIN_USERNAME="weblogic"
export $ADMIN_PASSWORD
export $ADMIN_USERNAME

# Create an empty domain
wlst.sh -skipWLSModuleScanning /u01/oracle/create-wls-domain.py
mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/
echo "username=${ADMIN_USERNAME}" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
echo "password=${ADMIN_PASSWORD}" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
${DOMAIN_HOME}/bin/setDomainEnv.sh


# Start Admin Server and tail the logs
echo 'Start Admin Server'
${DOMAIN_HOME}/startWebLogic.sh &

#Wait for Admin Server to start
echo 'Waiting for Admin Server to reach RUNNING state'
check_wls "started" localhost $ADMIN_PORT 2

#WLST online to configure DataSource
echo 'Doing WLST Online'
cd /u01/oracle
wlst -loadProperties /u01/oracle/oradatasource.properties /u01/oracle/ds-deploy.py 
