#! /bin/bash

#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Provision WebLogic Domain

domain_home="$3/$1"
username=$4
password=$5
as_port=$6
ms_name=$7
ms_port=$8

#Loop determining state of WLS
function check_wls {
    action=$1
    host=$2
    port=$3
    sleeptime=$4
    while true
    do
        sleep $sleeptime
        if [ "$action" == "started" ]; then
            started_url="http://$host:$port/weblogic/ready"
            echo -e "Waiting for WebLogic server to get $action, checking $started_url"
            status=`/usr/bin/curl -s -i $started_url | grep "200 OK"`
            echo "Status:" $status
            if [ ! -z "$status" ]; then
              break
            fi
        elif [ "$action" == "shutdown" ]; then
            shutdown_url="http://$host:$port"
            echo -e "Waiting for WebLogic server to get $action, checking $shutdown_url"
            status=`/usr/bin/curl -s -i $shutdown_url | grep "500 Can't connect"`
            if [ ! -z "$status" ]; then
              break
            fi
        fi
    done
    echo -e "WebLogic Server has $action"
}

echo 'Provisioning domain at ' $domain_home ' using WLST offline'
java weblogic.WLST provision-domain.py $*

dir=`pwd`
echo 'Changing current directory from ' $dir ' to ' $domain_home
cd $domain_home

mkdir -p $domain_home/servers/AdminServer/security && \
echo "username=$username" > $domain_home/servers/AdminServer/security/boot.identity && \
echo "password=$password" >> $domain_home/servers/AdminServer/security/boot.identity

echo 'Running Admin Server in background'
bin/startWebLogic.sh &

echo 'Waiting for Admin Server to reach RUNNING state'
check_wls "started" localhost $as_port 2

echo 'Copying managed server files files'
mkdir -p $domain_home/servers/$ms_name/security && \
cp $domain_home/servers/AdminServer/security/boot.properties $domain_home/servers/$ms_name/security/boot.properties

echo 'Running Managed Server in background'
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dweblogic.ListenAddress=localhost"
bin/startManagedWebLogic.sh $ms_name &

echo 'Waiting for Managed Server to reach RUNNING state'
check_wls "started" localhost $ms_port 5

echo 'Changing current directory back to ' $dir
cd $dir

echo 'Shutting down servers'
java weblogic.WLST shutdown-servers.py localhost $ms_port $username $password $ms_name
java weblogic.WLST shutdown-servers.py localhost $as_port $username $password 'AdminServer'

echo 'Removing Admin server files from the image'
# rm -rf $domain_home/servers/AdminServer
