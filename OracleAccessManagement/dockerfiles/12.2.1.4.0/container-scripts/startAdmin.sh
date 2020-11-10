#!/bin/sh
#
#
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#

#*************************************************************************
# script is used to start a WebLogic Admin server.
#*************************************************************************

export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME

# Start Admin server
LOGFILE=${DOMAIN_HOME}/logs/as.log
STSFILE=${DOMAIN_HOME}/logs/as.status
mkdir -p ${DOMAIN_HOME}/logs
rm -f ${LOGFILE} ${STSFILE}

echo "INFO: Starting the Admin Server..."
echo "INFO: Logs = ${LOGFILE}"
$DOMAIN_HOME/bin/startWebLogic.sh > ${LOGFILE} 2>&1 &

statusfile=/tmp/notifyfifo.$$
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
  grep -m 1 "<Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>"

  # notify the first pipeline stage that grep is done
  echo "RUNNING" > ${STSFILE}
  echo "INFO: Admin server is running"
  echo > ${statusfile}
}

# clean up
rm "${statusfile}"
if [ -f ${STSFILE} ]; then
  echo "INFO: Admin server running, ready to start managed server"
fi
