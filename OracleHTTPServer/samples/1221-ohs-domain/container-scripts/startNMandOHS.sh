#!/bin/sh
# Author: hemastuti.baruah@oracle.com
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#*************************************************************************
# script is used to start a NodeManager and OHS component server.
#  This script should be used only when node manager is configured per domain.
#  This script sets the following variables before starting
#  the node manager:
#
#  WL_HOME    - The root directory of your WebLogic installation
#  NODEMGR_HOME  - Absolute path to nodemanager directory under the configured domain home
#  DOMAIN_HOME - Absolute path to configured domain home
#  JAVA_HOME- Absolute path to jre inside the oracle home directory
#*************************************************************************
echo "MW_HOME=${MW_HOME:?"Please set MW_HOME"}"
echo "ORACLE_HOME=${ORACLE_HOME:?"Please set ORACLE_HOME"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME"}"
echo "OHS_COMPONENT_NAME=${OHS_COMPONENT_NAME:?"Please set OHS_COMPONENT_NAME"}"

export MW_HOME ORACLE_HOME DOMAIN_NAME OHS_COMPONENT_NAME


#Set WL_HOME, WLST_HOME, DOMAIN_HOME and NODEMGR_HOME
WL_HOME=${ORACLE_HOME}/wlserver
WLST_HOME=${ORACLE_HOME}/oracle_common/common/bin

DOMAIN_HOME=${ORACLE_HOME}/user_projects/domains/${DOMAIN_NAME}
export DOMAIN_HOME

NODEMGR_HOME=${DOMAIN_HOME}/nodemanager
export NODEMGR_HOME

#  Set JAVA_OPTIONS and JAVA_HOME for node manager
JAVA_OPTIONS="${JAVA_OPTIONS} -Dweblogic.RootDirectory=${DOMAIN_HOME}"
export JAVA_OPTIONS

JAVA_HOME=${ORACLE_HOME}/oracle_common/jdk/jre
export JAVA_HOME

#Declare and initializing NMSTATUS
declare -a NMSTATUS
NMSTATUS[0]="NOT RUNNING"

# If nodemanager$$.log does not exists,this is the first time configuring the NM 
# generate the NM password 

if [ !  -f /u01/oracle/logs/nodemanager$$.log ]; then
    
# Auto generate node manager  password
NM_PASSWORD=$(cat date| md5sum | fold -w 8 | head -n 1) 

echo ""
echo "    NodeManager Password Auto Generated:"
echo ""
echo "      ----> 'OHS' node manager password: $NM_PASSWORD"
echo ""

sed -i -e "s|NM_PASSWORD|$NM_PASSWORD|g" /u01/oracle/create-sa-ohs-domain.py

# Create an empty ohs domain
wlst.sh -skipWLSModuleScanning /u01/oracle/create-sa-ohs-domain.py
# Set the NM username and password in the properties file
echo "username=weblogic" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/nodemanager/config/nm_password.properties
echo "password=$NM_PASSWORD" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/nodemanager/config/nm_password.properties
${ORACLE_HOME}/oracle_common/common/bin/commEnv.sh
fi

# Start node manager
${WL_HOME}/server/bin/startNodeManager.sh > /u01/oracle/logs/nodemanager$$.log 2>&1 &
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

#Start OHS component only if Node Manager is up
if [ -f /u01/oracle/logs/Nodemanage$$.status ]; then
echo "Node manager running, hence starting OHS server"
${WLST_HOME}/wlst.sh /u01/oracle/container-scripts/start-ohs.py
echo "OHS server has been started "
fi


#Tail all server logs
tail -f ${DOMAIN_HOME}/nodemanager/nodemanager.log ${DOMAIN_HOME}/servers/*/logs/*.out
