#! /bin/bash

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


echo 'Changing current directory to ' $DOMAIN_HOME
cd $DOMAIN_HOME

echo 'Setting environment variable for username and password '
export EXTRA_JAVA_PROPERTIES="-Dweblogic.management.username=$ADMIN_USERNAME -Dweblogic.management.password=$ADMIN_PASSWORD"

echo 'Running Admin Server in background'
bin/startWebLogic.sh &

echo 'Waiting for Admin Server to reach RUNNING state'
check_wls "started" localhost $ADMIN_PORT 2

echo 'Doing WLST Online'
cd /u01/oracle
wlst -loadProperties /u01/oracle/jms-config.properties /u01/oracle/jms-config.py 
