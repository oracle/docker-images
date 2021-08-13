#!/bin/bash
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME

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

#=================================================================
#== MAIN Starts here...
#=================================================================
trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

export vol_name=u01
export adminhostname=${ADMIN_HOST}
export adminport=${ADMIN_PORT}
export ADMIN_PWD=${ADMIN_PASSWORD}
export server_host=${MS_HOST}
export server=${MANAGED_SERVER}
export SCRIPT_DIR=${SCRIPT_DIR:-/u01/oracle/dockertools}

# First Update the server in the domain
grepPat="<Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>"
if [ "$server" = "soa_server1" ]
then
  grepPat="SOA Platform is running and accepting requests"
fi

LOGDIR=${DOMAIN_HOME}/logs
LOGFILE=${LOGDIR}/$server-ms.log
mkdir -p ${LOGDIR}

export managed_host=`hostname`

# Update Listen Address for the Managed Server
export thehost=`hostname -I`
echo "INFO: Updating the listen address - ${thehost} ${server_host} for server ${server}"
cmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/updateListenAddressMS.py ${thehost} ${server} ${server_host} ${server_host} 7001 weblogic $ADMIN_PWD"
echo ${cmd}
${cmd} > ${DOMAIN_HOME}/logs/${server}-mslisten-${server_host}.log 2>&1

# Start Managed server
echo "INFO: Starting the managed server ${server}"
$DOMAIN_HOME/bin/startManagedWebLogic.sh $server "t3://"$adminhostname:$adminport > ${LOGFILE} 2>&1 &
statusfile=/tmp/notifyfifo.$$

echo "INFO: Waiting for the Managed Server to accept requests..."
rm -f ${statusfile}
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

RUN_MBEAN="true"
if [ "$server" = "oim_server1" ]
then
  if [ -e $CTR_DIR/MBEAN.suc ]
  then
      #Mbean has already been executed successfully, no need to rerun
      RUN_MBEAN="false"
      echo "INFO: OIM MBEAN has already been executed. Skipping..."
  fi
  if [ "$RUN_MBEAN" = "true" ]
  then
      echo "INFO: Running SOA Mbean"
      /u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $SCRIPT_DIR/oim_soa_integration.py weblogic $ADMIN_PWD $MS_HOST 14000 $adminhostname $adminport > ${LOGDIR}/oimsoaintegration.log 2>&1
      retval=$?
      if [ $retval -ne 0 ];
      then
          echo "ERROR: SOA OIM Integration Mbean Execution Failed. Check the logs at oimsoaintegration.log located in $DOMAIN_HOME/logs directory"
          exit
      else
          # Write the Mbean suc file...
          touch $CTR_DIR/MBEAN.suc
	  echo "INFO: OIM SOA Integration Mbean executed successfully."
      fi
  fi
fi

#Display the logs
#tail -f ${LOGFILE}
#tail -f $DOMAIN_HOME/servers/$server/logs/$server.log

childPID=$!
wait $childPID
