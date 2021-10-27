#!/bin/bash
#  Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# Author: Pratyush Dash
# This script is used to start the OID server
#=================================================================
export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME
export WL_HOME=$ORACLE_HOME/wlserver
export INSTANCE_NAME=${INSTANCE_NAME:-oid1}
export ADMIN_LISTEN_HOST=${ADMIN_LISTEN_HOST:-}
export ADMIN_LISTEN_PORT=${ADMIN_LISTEN_PORT:-}
export INSTANCE_HOST=${INSTANCE_HOST:-oidhost2}
export ORCL_ADMIN_PASSWORD=${ORCL_ADMIN_PASSWORD:-}


function _int() {
   echo "INFO: Stopping container."
   echo "INFO: SIGINT received, shutting down OID Server!"
  cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/stop_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $INSTANCE_NAME"
echo "Cmd is ${cfgCmd}"
  ${cfgCmd}
  exit;
}

#=================================================================
function _term() {
   echo "INFO: Stopping container."
   echo "INFO: SIGTERM received, shutting down OID Server!"
  cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/stop_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $INSTANCE_NAME"
echo "Cmd is ${cfgCmd}"
  ${cfgCmd}
  exit;
}

#=================================================================
function _kill() {
   echo "INFO: SIGKILL received, shutting down OID Server!"
  cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/stop_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $INSTANCE_NAME"
echo "Cmd is ${cfgCmd}"
  ${cfgCmd}
  exit;
}

export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME

#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

#Echo Env Details
# echo "Java Options: ${JAVA_OPTIONS}"
echo "Domain Root: ${DOMAIN_ROOT}"
echo "Domain Name: ${DOMAIN_NAME}"
echo "Domain Home: ${DOMAIN_HOME}"
echo "Oracle Home: ${ORACLE_HOME}"
echo "Logs Dir: ${DOMAIN_HOME}/logs"


# Start OID Server


if [ -f $DOMAIN_HOME/.oidconfigured ];
   if [ $oid_instance != "oid1" ];then  
   echo "Creating OID instance Phase"
   echo "=========================="
   . ${ORACLE_HOME}/wlserver/server/bin/setWLSEnv.sh
   echo "${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning {SCRIPT_DIR}/create_start_instance.py -user $ADMIN_USER -password $ADMIN_PASSWORD  -instanceName $INSTANCE_NAME -machineName $INSTANCE_HOST -admin_Port $ADMIN_LISTEN_PORT -admin_Hostname $ADMIN_LISTEN_HOST" 
   cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/create_start_instance.py -user $ADMIN_USER -password $ADMIN_PASSWORD  -instanceName $INSTANCE_NAME -machineName $INSTANCE_HOST -admin_Port $ADMIN_LISTEN_PORT -admin_Hostname $ADMIN_LISTEN_HOST"
   echo "Cmd is ${cfgCmd}"
   ${cfgCmd}
   retval=$?
   if [ $retval -ne 0 ];
   then
      echo "Starting OID Failed.. Please check the server Logs"
      exit
   fi
   fi
fi
