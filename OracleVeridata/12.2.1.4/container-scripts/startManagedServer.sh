#!/bin/bash
#
#
#
#
# Copyright (c) 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# Author:Arnab Nandi <arnab.x.nandi@oracle.com>


export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME=${DOMAIN_ROOT}/${VERIDATA_DOMAIN_NAME}
echo "Domain Home is: " $DOMAIN_HOME

#=================================================================
function _int() {
   echo "INFO: Stopping container."
   echo "INFO: SIGINT received, shutting down Managed Server!"
   ${DOMAIN_HOME}/veridata/bin/veridataServer.sh stop
   exit;
}

#=================================================================
function _term() {
   echo "INFO: Stopping container."
   echo "INFO: SIGTERM received, shutting down Managed Server!"
   ${DOMAIN_HOME}/veridata/bin/veridataServer.sh stop
   exit;
}

#=================================================================
function _kill() {
   echo "INFO: SIGKILL received, shutting down Managed Server!"
   ${DOMAIN_HOME}/veridata/bin/veridataServer.sh stop
   exit;
}

#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

extract_env() {
   env_value=`awk '{print}' $2 | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo $1=$env_value`
      echo " env_arg: $env_arg"
      export $env_arg
   fi
}

extract_env ADMIN_PORT ${ORACLE_HOME}/vdt.env


admin_host() {
   adminhost=${ADMIN_CONTAINER_NAME:-"OggVdtAdminContainer"}
   echo "adminhost= ${adminhost}"
}


admin_host

echo "USER $(id -u -n)"

#id -u -n

# Wait for AdminServer to become available for any subsequent operation
connectString="${ADMIN_CONTAINER_NAME}/${ADMIN_PORT}"
#connectString="${ADMIN_HOST}/${ADMIN_LISTEN_PORT}"
/u01/oracle/container-scripts/waitForAdmin.sh ${connectString}

MANAGED_SERVER="VERIDATA_server1"
LOGDIR=${DOMAIN_HOME}/servers/${MANAGED_SERVER}/logs
LOGFILE=${LOGDIR}/${MANAGED_SERVER}.log
MS_SECURITY=${DOMAIN_HOME}/servers/${MANAGED_SERVER}/security
mkdir -p ${LOGDIR}
mkdir -p ${MS_SECURITY}

if [ ! -f "${MS_SECURITY}/boot.properties" ]
then
  mkdir -p ${MS_SECURITY}
  chmod +w ${MS_SECURITY}
  echo "Make directory ${MS_SECURITY} to create boot.properties"
  echo "username=${VERIDATA_USER}" >> ${MS_SECURITY}/boot.properties
  echo "password=${VERIDATA_PASSWORD}" >> ${MS_SECURITY}/boot.properties


  mangedFile=${DOMAIN_HOME}/bin/startManagedWebLogic.sh
  managedFileBak=${DOMAIN_HOME}/bin/startManagedWebLogic.sh.bak
  search='WLS_USER="'
  replace='WLS_USER=${VERIDATA_USER}'
  sed 's/${search}/${replace}/g' ${mangedFile} > ${managedFileBak}

  search='WLS_PW=""'
  replace='WLS_PW=${VERIDATA_PASSWORD}'
  sed 's/${search}/${replace}/g' ${managedFileBak} > ${mangedFile}

fi

#Set Java options
export JAVA_OPTIONS=${JAVA_OPTIONS}


${DOMAIN_HOME}/bin/setDomainEnv.sh

# Start Veridata server
echo "INFO: Starting the managed server ${MANAGED_SERVER}"
${DOMAIN_HOME}/veridata/bin/veridataServer.sh start


if [ ! -f "${LOGFILE}" ]
then
  $DOMAIN_HOME/bin/startManagedWebLogic.sh ${MANAGED_SERVER} "http://"${ADMIN_CONTAINER_NAME}:${ADMIN_PORT} > ${LOGFILE} 2>&1 &
fi

tail -f ${LOGFILE}
childPID=$!
wait $childPID


