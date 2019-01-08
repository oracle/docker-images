#!/bin/bash
# Author: prabhat.kishore@oracle.com
# Copyright (c) 2017-2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#*************************************************************************
#  This script is used to create a standalone OHS domain and start NodeManager, OHS instance.
#  This script sets the following variables:
#
#  WL_HOME    - The Weblogic home directory
#  NODEMGR_HOME  - Absolute path to Nodemanager directory under the configured domain home
#  DOMAIN_HOME - Absolute path to configured domain home
#  JAVA_HOME- Absolute path to jre inside the oracle home directory
#*************************************************************************
########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the server!"
   ${WLST_HOME}/wlst.sh /u01/oracle/container-scripts/stop-ohs.py
   ${DOMAIN_HOME}/bin/stopNodeManager.sh
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

echo "MW_HOME=${MW_HOME:?"Please set MW_HOME"}"
echo "ORACLE_HOME=${ORACLE_HOME:?"Please set ORACLE_HOME"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME"}"
echo "OHS_COMPONENT_NAME=${OHS_COMPONENT_NAME:?"Please set OHS_COMPONENT_NAME"}"

export MW_HOME ORACLE_HOME DOMAIN_NAME OHS_COMPONENT_NAME


#Set WL_HOME, WLST_HOME, DOMAIN_HOME and NODEMGR_HOME
WL_HOME=${ORACLE_HOME}/wlserver
WLST_HOME=${ORACLE_HOME}/oracle_common/common/bin
echo "WLST_HOME=${WLST_HOME}"

DOMAIN_HOME=${ORACLE_HOME}/user_projects/domains/${DOMAIN_NAME}
export DOMAIN_HOME
echo "DOMAIN_HOME=${DOMAIN_HOME}"

NODEMGR_HOME=${DOMAIN_HOME}/nodemanager
export NODEMGR_HOME

echo "PATH=${PATH}"
PATH=$PATH:/usr/java/default/bin:/u01/oracle/ohssa/oracle_common/common/bin
export PATH
echo "PATH=${PATH}"

#  Set JAVA_OPTIONS and JAVA_HOME for node manager
JAVA_OPTIONS="${JAVA_OPTIONS} -Dweblogic.RootDirectory=${DOMAIN_HOME}"
export JAVA_OPTIONS

JAVA_HOME=${ORACLE_HOME}/oracle_common/jdk/jre
export JAVA_HOME
 
PROPERTIES_FILE=/u01/oracle/bootdir/domain.properties
export PROPERTIES_FILE

#Declare and initializing NMSTATUS
declare -a NMSTATUS
NMSTATUS[0]="NOT RUNNING"

# If nodemanager$$.log does not exists,this is the first time configuring the NM 
# generate the NM password 

if [ !  -f /u01/oracle/logs/nodemanager$$.log ]; then

# Get Password
NM_PASSWORD=`awk '{print $1}' $PROPERTIES_FILE | grep password | cut -d "=" -f2`
if [ -z "$NM_PASSWORD" ]; then
   echo "The Node Manager password is blank. It must be set in the properties file."
   exit
fi
    
wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/create-sa-ohs-domain.py
# Set the NM username and password in the properties file
echo "username=weblogic" >> /u01/oracle/ohssa/user_projects/domains/ohsDomain/config/nodemanager/nm_password.properties
echo "password=$NM_PASSWORD" >> /u01/oracle/ohssa/user_projects/domains/ohsDomain/config/nodemanager/nm_password.properties
mv /u01/oracle/container-scripts/helloWorld.html ${ORACLE_HOME}/user_projects/domains/ohsDomain/config/fmwconfig/components/OHS/ohs1/htdocs/helloWorld.html

fi

# Start node manager
${DOMAIN_HOME}/bin/startNodeManager.sh > /u01/oracle/logs/nodemanager$$.log 2>&1 &
statusfile=/tmp/notifyfifo.$$

#Check if Node Manager is up and running by inspecting logs
mkfifo "${statusfile}" || exit 1
{
    # run tail in the background so that the shell can kill tail when notified that grep has exited
    tail -f /u01/oracle/logs/nodemanager$$.log &
    # remember tail's PID
    tailpid=$!
    # wait for notification that grep has exited
    read templine <${statusfile}
                        echo ${templine}
    # grep has exited, time to go
    kill "${tailpid}"
} | {
    grep -m 1 "Secure socket listener started on port 5556"
    # notify the first pipeline stage that grep is done
        echo "RUNNING"> /u01/oracle/logs/Nodemanage$$.status
        echo "Node manager is running"
    echo >${statusfile}
}
# clean up temporary files
rm "${statusfile}"

#Check if configureWLSProxyPlugin.sh needs to be invoked
if [ -f /config/custom_mod_wl_ohs.conf ]; then
configureWLSProxyPlugin.sh
fi

#Start OHS component only if Node Manager is up
if [ -f /u01/oracle/logs/Nodemanage$$.status ]; then
echo "Node manager running, hence starting OHS server"
${WLST_HOME}/wlst.sh /u01/oracle/container-scripts/start-ohs.py
echo "OHS server has been started "
fi

#Tail all server logs
tail -f ${DOMAIN_HOME}/nodemanager/nodemanager.log ${DOMAIN_HOME}/servers/*/logs/*.log &

childPID=$!
wait $childPID
