#!/bin/bash
#
# Copyright (c) 2016, 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

# Author:nevin.cleetus@oracle.com

export DOMAIN_NAME=${DOMAIN_NAME:-soainfra}
export DOMAIN_ROOT=${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}
export DOMAIN_HOME=${DOMAIN_ROOT}/${DOMAIN_NAME}

#=================================================================
function _int() {
   echo "INFO: Stopping container."
   echo "INFO: SIGINT received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh ${MANAGED_SERVER} "http://"${ADMIN_HOST}:${ADMIN_PORT}
   exit;
}

#=================================================================
function _term() {
   echo "INFO: Stopping container."
   echo "INFO: SIGTERM received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh ${MANAGED_SERVER} "http://"${ADMIN_HOST}:${ADMIN_PORT}
   exit;
}

#=================================================================
function _kill() {
   echo "INFO: SIGKILL received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh ${MANAGED_SERVER} "http://"${ADMIN_HOST}:${ADMIN_PORT}
   exit;
}

#calling soa extension function script
/u01/oracle/container-scripts/soaExtFun.sh


#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

export vol_name=u01

if [[ "$MANAGED_SERVER" =~ "soa" ]]
then
  grepPat="SOA Platform is running and accepting requests"
elif [[ "$MANAGED_SERVER" =~ "osb" ]]
then
  grepPat="<Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>"
else
  echo "ERROR: Invalid domain type. Cannot start the servers"
  exit
fi

LOGDIR=${DOMAIN_HOME}/logs/${MANAGED_SERVER}
LOGFILE=${LOGDIR}/ms.log
mkdir -p ${LOGDIR}

export thehost=`hostname -I`
echo "INFO: Updating the listen address - ${thehost}"
/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/updListenAddress.py $vol_name $thehost ${MANAGED_SERVER} > ${LOGDIR}/mslisten.log 2>&1

# Set boot.properties
#
# Password less Managed Server starting
#======================================
if [ ! -z "${ADMIN_PASSWORD}" ]; then
   echo "INFO: creating boot.properties for ${MANAGED_SERVER}"
   mkdir -p $DOMAIN_HOME/servers/${MANAGED_SERVER}/security/
   echo "username=weblogic" > $DOMAIN_HOME/servers/${MANAGED_SERVER}/security/boot.properties
   echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/${MANAGED_SERVER}/security/boot.properties
fi

# Start SOA server
echo "INFO: Starting the managed server ${MANAGED_SERVER}"
$DOMAIN_HOME/bin/startManagedWebLogic.sh ${MANAGED_SERVER} "http://"${ADMIN_HOST}:${ADMIN_PORT} > ${LOGFILE} 2>&1 &
statusfile=/tmp/notifyfifo.$$

echo "INFO: Waiting for the Managed Server to accept requests..."
rm -f "${statusfile}"
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
  echo "RUNNING"> ${LOGDIR}/ms.status
  echo "INFO: Managed Server is running"
  echo >${statusfile}
}

# clean up
rm -f "${statusfile}"
if [ -f ${LOGDIR}/ms.status ]; then
  echo "INFO: Managed server has been started"
fi

childPID=$!
wait $childPID
