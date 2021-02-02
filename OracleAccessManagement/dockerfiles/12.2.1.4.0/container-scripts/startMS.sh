#!/bin/bash
#
# # Copyright (c) 2020, 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#
#
# This script is used to start the Managed server
#=================================================================
function _int() {
   echo "INFO: Stopping container."
   echo "INFO: SIGINT received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $server "t3://"$adminhostname:$adminport
   exit;
}

#=================================================================
function _term() {
   echo "INFO: Stopping container."
   echo "INFO: SIGTERM received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $server "t3://"$adminhostname:$adminport
   exit;
}

#=================================================================
function _kill() {
   echo "INFO: SIGKILL received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $server "t3://"$adminhostname:$adminport
   exit;
}

export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME

#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

export server=${MS_NAME:-$1}
export adminhostname=${ADMIN_LISTEN_HOST:-$2}
export adminport=${ADMIN_LISTEN_PORT:-$3}
export server_host=${MS_HOST:-$4}

#Echo Env Details
# echo "Java Options: ${JAVA_OPTIONS}"
echo "Domain Root: ${DOMAIN_ROOT}"
echo "Domain Name: ${DOMAIN_NAME}"
echo "Domain Home: ${DOMAIN_HOME}"
echo "Oracle Home: ${ORACLE_HOME}"
echo "Logs Dir: ${DOMAIN_HOME}/logs"

# First Update the server in the domain
grepPat="<Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>"

LOGFILE=${DOMAIN_HOME}/logs/$server-ms-$server_host.log
mkdir -p ${DOMAIN_HOME}/logs

# Wait for AdminServer to become available for any subsequent operation
${SCRIPT_DIR}/waitForAdminServer.sh

# Update Listen Address for the Managed Server
export thehost=`hostname -I`
echo "INFO: Updating the listen address - ${thehost} ${server_host} for server ${server}"
cmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/updateListenAddress.py ${thehost} ${server} ${server_host}"
echo ${cmd}
${cmd} > ${DOMAIN_HOME}/logs/${server}-mslisten-${server_host}.log 2>&1

# Password less Managed Server starting
#======================================
   echo "INFO: creating boot.properties"
   mkdir -p $DOMAIN_HOME/servers/${server}/security/
   echo "username=weblogic" > $DOMAIN_HOME/servers/${server}/security/boot.properties
   echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/${server}/security/boot.properties

# Start Managed Server
echo "INFO: Starting the managed server ${server}"
echo "INFO: Logs = ${LOGFILE}"
$DOMAIN_HOME/bin/startManagedWebLogic.sh $server "t3://"$adminhostname:$adminport > ${LOGFILE} 2>&1 &
statusfile=/tmp/notifyfifo.$$

echo "INFO: Waiting for the Managed Server to accept requests..."
mkfifo "${statusfile}" || exit 1
{
  # run tail in the background so that the shell can kill tail when notified 
  # that grep has exited
  tail -f ${LOGFILE} &
  # remember tail's PID
  tailpid=$!
  # wait for notification that grep has exited
  read templine <${statusfile}
  echo ${templine}
  # grep has exited, time to go
  kill "${tailpid}"
} | {
  grep -m 1 "${grepPat}"
  # notify the first pipeline stage that grep is done
  echo "RUNNING"> ${DOMAIN_HOME}/logs/${server}-ms-${server_host}.status
  echo "INFO: Managed Server is running"
  echo >${statusfile}
}

# clean up
rm "${statusfile}"
if [ -f ${DOMAIN_HOME}/logs/${server}-ms-${server_host}.status ]; then
  echo "INFO: Managed server has been started"
fi

childPID=$!
wait $childPID
