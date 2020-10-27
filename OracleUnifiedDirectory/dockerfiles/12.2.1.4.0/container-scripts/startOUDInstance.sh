#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# Script to start OUD Instance
# 

# Variables for this script to work
source ${SCRIPT_DIR}/setEnvVars.sh
source ${SCRIPT_DIR}/common_functions.sh

# ---------------------------------------------------------------------------
# SIGINT handler
# ---------------------------------------------------------------------------
function int_oud() {
    echo "---------------------------------------------------------------"
    echo "[$(date)] - SIGINT received, shutting down OUD instance!"
    echo "---------------------------------------------------------------"
    ${OUD_INST_HOME}/bin/stop-ds >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# SIGTERM handler
# ---------------------------------------------------------------------------
function term_oud() {
    echo "---------------------------------------------------------------"
    echo "[$(date)] - SIGTERM received, shutting down OUD instance!"
    echo "---------------------------------------------------------------"
    ${OUD_INST_HOME}/bin/stop-ds >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# SIGKILL handler
# ---------------------------------------------------------------------------
function kill_oud() {
    echo "---------------------------------------------------------------"
    echo "[$(date)] - SIGKILL received, shutting down OUD instance!"
    echo "---------------------------------------------------------------"
kill -9 $childPID
}

# Set SIGINT handler
trap int_oud SIGINT

# Set SIGTERM handler
trap term_oud SIGTERM

# Set SIGKILL handler
trap kill_oud SIGKILL

# Log OUD Instance Version related details
if [ -f ${oudInstanceDetailsFile} ]
then
  mv ${oudInstanceDetailsFile} ${oudInstanceDetailsFile}.old
fi
${OUD_INST_HOME}/bin/start-ds -F > ${oudInstanceDetailsFile}

# Perform Instance upgrade if requried
if [ -f ${oudInstanceDetailsFile}.old ]
then
  diffCount=$(diff ${oudInstanceDetailsFile}.old ${oudInstanceDetailsFile} | wc -l)
  if [ ${diffCount} -ne 0 ]
  then
	echo "[$(date)] - There is diffence between ${oudInstanceDetailsFile}.org and ${oudInstanceDetailsFile}"
	echo "[$(date)] - Executiong start-ds with --upgrade parameter"   
	${OUD_INST_HOME}/bin/start-ds --upgrade
  fi
fi

# Support for Starting OUD Instance in container in Debug mode
startDsScript=start-ds
# Check if OUD instance is requried to be started in Debug mode
if [ "${runStartDsInDebug}" = "true" ]
then
  echo "[$(date)] - Generating start-ds_debug..."
  ${SCRIPT_DIR}/generate-start-ds_debug.sh ${OUD_INST_HOME}/bin ${startDsDebugPort} ${startDsDebugSuspend}
  startDsScript=start-ds_debug
  restartOUDInstAfterConfig=true
fi

# Support for Java security option
### function call for java security config OUD-12339
#java_security_config

#####function call for Schema config OUD-12343
#schema_config

# Start OUD instance
echo "---------------------------------------------------------------"
echo "[$(date)] - Start OUD instance (${OUD_INST_HOME}):"
echo "---------------------------------------------------------------"
echo "[$(date)] - Before invoking start-ds, let's check the status"
${SCRIPT_DIR}/checkOUDInstance.sh
checkOudError=$?
if [ ${checkOudError} -gt 0 ]; then
  echo "[$(date)] - Seems, OUD Instance is not running. Invoking ${startDsScript} ..."
  ${OUD_INST_HOME}/bin/${startDsScript}  2>&1 | tee -a ${startDsCmdLogs}
else
  echo "[$(date)] - Seems, OUD Instance is already running."
  if [ "${restartOUDInstAfterConfig}" = "true" ]
  then
	echo "[$(date)] - As OUD instance is required to be started based on variable value 'true' for restartOUDInstAfterConfig. Stopping the running instance ..."
	${OUD_INST_HOME}/bin/stop-ds 2>&1 | tee -a ${stopDsCmdLogs}
	echo "[$(date)] - Invoking ${startDsScript} ..."
	${OUD_INST_HOME}/bin/${startDsScript} 2>&1 | tee -a ${startDsCmdLogs}
  else
	echo "[$(date)] - start-ds would not be invoked."
  fi
fi

echo "[$(date)] - Tail on server log and wait. Without this, container will exit." 2>&1 | tee -a ${oudInstanceConfigStatus}
mkdir -p ${OUD_INST_HOME}/logs
touch ${OUD_INST_HOME}/logs/server.out
tail -f ${OUD_INST_HOME}/logs/server.out &

childPID=$!
wait $childPID
