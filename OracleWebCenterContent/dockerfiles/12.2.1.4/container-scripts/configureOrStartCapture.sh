#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function validate_parameter {
  name=$1
  value=$2
  if [ -z $value ]
  then
    echo "ERROR: Please set '$name' in configmap[webcenter.env.list file]."
    echo ""       
    exit 1
  fi
}

# validate HOSTNAME
validate_parameter "HOSTNAME" $HOSTNAME
validate_parameter "CAPTURE_PORT" $CAPTURE_PORT
validate parameter "CAPTURE_HOST_PORT" $CAPTURE_HOST_PORT

export vol_name=u01
export server=capture_server1
export CAPTURE_PORT=$CAPTURE_PORT
export CAPTURE_HOST_PORT=$CAPTURE_HOST_PORT

# get the hostname FQDN
export hostname=$HOSTNAME

echo "Environment variables"
echo "====================="
echo ""
echo "HOSTNAME=${hostname}"
echo "vol_name=${vol_name}"
echo "CAPTURE_PORT=${CAPTURE_PORT}"
echo "CAPTURE_HOST_PORT=${CAPTURE_HOST_PORT}"
echo ""
echo ""

if [ -z ${KEEP_CONTAINER_ALIVE} ]
then
   # by default we always keep this flag ON
   export KEEP_CONTAINER_ALIVE="true"
fi

export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
export CONTAINERCONFIG_DIR_NAME="container-data"
export CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
export CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"

# remove the space from hostname
hostname=`echo $hostname | sed  's/^[[:space:]]*//'`

# find & replace '.' from hostname
hostalias=`echo $hostname | sed  's/[.]//g'`
truncatedhostname=${hostalias}


if [ ${#truncatedhostname} -gt "20" ]
then
    truncatedhostname=${truncatedhostname:0:10}
fi

#start capture Server
sh /$vol_name/oracle/container-scripts/startManagedServer.sh $server


export servers=capture
echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $hostname $servers
fi

