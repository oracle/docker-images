#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
usage() {
    echo "Usage:"
    echo " keepContainerAlive.sh logs_dir hostname server_name"
}

if [ $# -ne 3 ]; then
    usage
    exit 1
fi	

# Read the argument values
# Logs directory where log file will be created
LOGS_DIR=$1

# hostname
HOST_NAME=$2

# Server name
SERVER_NAME=$3

# Timestamp to make file name unique
TIMESTAMP=$(date +%y%m%d%H%M)

CONTAINER_LOG="${LOGS_DIR}/WC_Container-success-${HOST_NAME}-${SERVER_NAME}-${TIMESTAMP}.log"

# Delete the file if it exists already
rm -f $CONTAINER_LOG

CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
if [ -e $CONTAINER_LOG ]
then
  cat > $CONTAINER_LOG<<-EOF
  ===============================================
  POD Server    : $SERVER_NAME
  POD IP Address: $HOST_NAME
  Set up time   : $CURRENT_TIME
  WCP POD Container is in running state...
  ===============================================
EOF
  tail -f $CONTAINER_LOG &
  childPID=$!
  wait ${childPID}
else
  sleep infinity
fi