#!/bin/bash
#
# Author:vivek.raj@oracle.com

export DOMAIN_NAME=${DOMAIN_NAME:-soainfra}
export DOMAIN_ROOT=${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}
export DOMAIN_HOME=${DOMAIN_ROOT}/${DOMAIN_NAME}

#=================================================================
function _int() {
   echo "INFO: Stopping container."
   echo "INFO: SIGINT received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $server "http://"$adminhostname:$adminport
   exit;
}

#=================================================================
function _term() {
   echo "INFO: Stopping container."
   echo "INFO: SIGTERM received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $server "http://"$adminhostname:$adminport
   exit;
}

#=================================================================
function _kill() {
   echo "INFO: SIGKILL received, shutting down Managed Server!"
   $DOMAIN_HOME/bin/stopManagedWebLogic.sh $server "http://"$adminhostname:$adminport
   exit;
}

#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

export vol_name=u01
export adminhostname=$adminhostname
export adminport=$adminport

# First Update the server in the domain
grepPat="<Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>"
if [ "$DOMAIN_TYPE" = "soa" ] || [ "$DOMAIN_TYPE" = "bpm" ]
then
  server="soa_server1"
  grepPat="SOA Platform is running and accepting requests"
elif [  "$DOMAIN_TYPE" = "osb" ]
then
  server="osb_server1"
else
  echo "ERROR: Invalid domain type. Cannot start the servers"
  exit
fi

LOGDIR=${DOMAIN_HOME}/logs
LOGFILE=${LOGDIR}/ms.log
mkdir -p ${LOGDIR}

export soa_host=`hostname -I`
echo "INFO: Updating the Host name listen address"
/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/dockertools/updListenAddress.py $vol_name $soa_host $server > ${LOGDIR}/mslisten.log 2>&1

# Start SOA server
echo "INFO: Starting the managed server ${server}"
$DOMAIN_HOME/bin/startManagedWebLogic.sh $server "http://"$adminhostname:$adminport > ${LOGFILE} 2>&1 &
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
  echo "RUNNING"> ${LOGDIR}/ms.status
  echo "INFO: Managed Server is running"
  echo >${statusfile}
}

# clean up
rm "${statusfile}"
if [ -f ${LOGDIR}/ms.status ]; then
  echo "INFO: Managed server has been started"
fi

childPID=$!
wait $childPID
