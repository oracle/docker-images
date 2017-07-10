#!/bin/bash
# Author: hemastuti.baruah@oracle.com
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#*************************************************************************
#  This script is used to start a NodeManager and OHS component server.
#  It should be used only when node manager is configured per domain.
#  It sets the following variables before starting
#  the NodeManager:
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
echo "WL_HOME=${WL_HOME}"
WLST_HOME=${ORACLE_HOME}/oracle_common/common/bin
export WLST_HOME

DOMAIN_HOME=${ORACLE_HOME}/user_projects/domains/${DOMAIN_NAME}
export DOMAIN_HOME
echo "DOMAIN_HOME=${DOMAIN_HOME}"

echo "PATH=${PATH}"
PATH=$PATH:/usr/java/default/bin:/u01/oracle/ohssa/oracle_common/common/bin
export PATH
echo "PATH=${PATH}"

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

#Start OHS component only if Node Manager is up
if [ -f /u01/oracle/logs/Nodemanage$$.status ]; then
echo "Node manager running, hence starting OHS server"
${WLST_HOME}/wlst.sh /u01/oracle/container-scripts/start-ohs.py
echo "OHS server has been started "
fi

#/bin/bash

childPID=$!
#wait $childPID

#Tail all server logs
tail -f ${DOMAIN_HOME}/nodemanager/nodemanager.log ${DOMAIN_HOME}/servers/*/logs/*.log

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the server!"
   ${WLST_HOME}/wlst.sh /u01/oracle/container-scripts/stop-ohs.py
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
