#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates. All rights reserved.
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
   ${WLST_HOME}/wlst.sh /u01/oracle/stop-ohs.py
   ${DOMAIN_HOME}/bin/stopNodeManager.sh
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

echo "ORACLE_HOME=${ORACLE_HOME:?"Please set ORACLE_HOME"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME"}"
echo "OHS_COMPONENT_NAME=${OHS_COMPONENT_NAME:?"Please set OHS_COMPONENT_NAME"}"

export ORACLE_HOME DOMAIN_NAME OHS_COMPONENT_NAME


#Set WL_HOME, WLST_HOME, DOMAIN_HOME, NODEMGR_HOME, and LOGS_DIR
#WL_HOME=${ORACLE_HOME}/wlserver
WLST_HOME=${ORACLE_HOME}/oracle_common/common/bin
echo "WLST_HOME=${WLST_HOME}"

DOMAIN_HOME=${ORACLE_HOME}/user_projects/domains/${DOMAIN_NAME}
export DOMAIN_HOME
echo "DOMAIN_HOME=${DOMAIN_HOME}"

NODEMGR_HOME=${DOMAIN_HOME}/nodemanager
export NODEMGR_HOME


PATH=$PATH:${ORACLE_HOME}:/usr/java/default/bin:${ORACLE_HOME}/oracle_common/common/bin
export PATH
echo "PATH=${PATH}"

LOG_DIR=${ORACLE_HOME}/logs
export  LOG_DIR
echo "LOG_DIR=${LOG_DIR}"

#  Set JAVA_OPTIONS and JAVA_HOME for node manager
JAVA_OPTIONS="${JAVA_OPTIONS} -Dweblogic.RootDirectory=${DOMAIN_HOME}"
export JAVA_OPTIONS

JAVA_HOME=${ORACLE_HOME}/oracle_common/jdk/jre
export JAVA_HOME
 
mkdir -p $ORACLE_HOME/bootdir
PROPERTIES_FILE=/u01/oracle/bootdir/domain.properties
export PROPERTIES_FILE

if [ ! -e "$PROPERTIES_FILE" ]; then
   echo "A properties file with the username and password needs to be supplied."
   exit
fi

# If nodemanager$$.log does not exists,this is the first time configuring the NM 
# generate the NM password 

if [ !  -f /u01/oracle/logs/nodemanager$$.log ]; then

# Get Username
NM_USER=`awk '{print $1}' $PROPERTIES_FILE | grep username | cut -d "=" -f2`
if [ -z "$NM_USER" ]; then
   echo "The Node Manager username is blank. It must be set in the properties file."
   exit
fi

# Get Password
NM_PASSWORD=`awk '{print $1}' $PROPERTIES_FILE | grep password | cut -d "=" -f2`
if [ -z "$NM_PASSWORD" ]; then
   echo "The Node Manager password is blank. It must be set in the properties file."
   exit
fi
    
wlst.sh -skipWLSModuleScanning -loadProperties $PROPERTIES_FILE /u01/oracle/create-sa-ohs-domain.py
# Set the NM username and password in the properties file
echo "username=$NM_USER" >> ${DOMAIN_HOME}/config/nodemanager/nm_password.properties
echo "password=$NM_PASSWORD" >> ${DOMAIN_HOME}/config/nodemanager/nm_password.properties
mv /u01/oracle/helloWorld.html ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/htdocs/helloWorld.html

echo "Copying Configuration to OHS Instance"
conf=$(ls -l /u01/oracle/config/moduleconf/*.conf 2>/dev/null | wc -l)
if [ $conf -gt 0 ]
then
  echo "  Copying moduleconf conf files to OHS Instance"
  cp  -L /u01/oracle/config/moduleconf/*.conf ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/moduleconf 
  find ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/moduleconf -name '.*' -exec rm -rf {} \; > /dev/null 2>&1
fi

conf=$(ls -l /u01/oracle/config/httpd/*.conf 2>/dev/null | wc -l)
if [ $conf -gt 0 ]
then
   echo "  Copying root conf files OHS Instance"
   cp  -L /u01/oracle/config/httpd/*.conf ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME
   find ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME -name '.*' -exec rm -rf {} \; > /dev/null 2>&1
fi

conf=$(ls -l /u01/oracle/config/wallet/* 2>/dev/null | wc -l)
if [ $conf -gt 0 ]
then
   echo "  Copying OHS Wallets to OHS Instance"
   mkdir -p ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/keystores > /dev/null 2>&1
   cp  -Lr /u01/oracle/config/wallet/* ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/keystores/ 
   find ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/keystores -name '.*' -exec rm -rf {} \; > /dev/null 2>&1
fi

htdocs=$(ls -l /u01/oracle/config/htdocs/* 2>/dev/null | wc -l)
if [ $htdocs -gt 0 ]
then
   echo "  Copying htdocs to OHS Instance"
   cp  -Lr /u01/oracle/config/htdocs/* ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/htdocs 
   find ${DOMAIN_HOME}/config/fmwconfig/components/OHS/$OHS_COMPONENT_NAME/htdocs -name '.*' -exec rm -rf {} \; > /dev/null 2>&1
fi

if [ "$DEPLOY_WG" = "true" ]
then
    echo "Deploying Webgate"
    if ! [ -e /u01/oracle/config/webgate/config/ObAccessClient.xml ]
    then
       echo "Must provide WebGate Configutaion files when DEPLOY_WG is true."
       exit 1
    fi
    cd $ORACLE_HOME/webgate/ohs/tools/deployWebGate/ || exit
    ./deployWebGateInstance.sh -w ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME} -oh $ORACLE_HOME
    cd $ORACLE_HOME/webgate/ohs/tools/setup/InstallTools || exit
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME/lib
    ./EditHttpConf -w ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME} -oh $ORACLE_HOME
    echo "  Adding OAP API exclusion to webgate.conf"
    echo "<LocationMatch \"/iam/access/binding/api/v10/oap\">" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "    require all granted" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "</LocationMatch>" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "<LocationMatch \"/helloWorld.html\">" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "    require all granted" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "</LocationMatch>" >> ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate.conf
    echo "  Copying WebGate Artifacts to Oracle Instance"
    cp  -rL /u01/oracle/config/webgate ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME} 
    find ${DOMAIN_HOME}/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}/webgate -name '.*' -exec rm -rf {} \; > /dev/null 2>&1
else
    echo "WebGate not deployed"
fi

fi

# Start node manager
mkdir ${LOG_DIR}
${DOMAIN_HOME}/bin/startNodeManager.sh > ${LOG_DIR}/nodemanager$$.log 2>&1 &
statusfile=/tmp/notifyfifo.$$

#Check if Node Manager is up and running by inspecting logs
mkfifo "${statusfile}" || exit 1
{
    # run tail in the background so that the shell can kill tail when notified that grep has exited
    tail -f  ${LOG_DIR}/nodemanager$$.log &
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
        echo "RUNNING"> ${LOG_DIR}/Nodemanage$$.status
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
if [ -f ${LOG_DIR}/Nodemanage$$.status ]; then
echo "Node manager running, hence starting OHS server"
${WLST_HOME}/wlst.sh -loadProperties $PROPERTIES_FILE /u01/oracle/start-ohs.py
echo "OHS server has been started"
fi

#Tail all server logs
tail -f ${DOMAIN_HOME}/nodemanager/nodemanager.log ${DOMAIN_HOME}/servers/*/logs/*.log &

childPID=$!
wait $childPID
