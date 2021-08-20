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
validate_parameter "WCCADF_PORT" $WCCADF_PORT
validate parameter "WCCADF_HOST_PORT" $WCCADF_HOST_PORT
validate_parameter "UCM_INTRADOC_PORT" $UCM_INTRADOC_PORT

export vol_name=u01
export server=WCCADF_server1
export WCCADF_PORT=$WCCADF_PORT
export WCCADF_HOST_PORT=$WCCADF_HOST_PORT
export UCM_INTRADOC_PORT=$UCM_INTRADOC_PORT

# get the hostname FQDN
export hostname=$HOSTNAME

echo "Environment variables"
echo "====================="
echo ""
echo "HOSTNAME=${hostname}"
echo "vol_name=${vol_name}"
echo "WCCADF_PORT=${WCCADF_PORT}"
echo "WCCADF_HOST_PORT=${WCCADF_HOST_PORT}"
echo "UCM_INTRADOC_PORT=${UCM_INTRADOC_PORT}"
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

# Extra step for WCCADF
# Update the WccAdf.ear with the proper HOSTNAME and UCM_INTRADOC_PORT.
# The ear file will be under /u01/oracle/wccontent/wccadf/WccAdf.ear
echo " Keeping backup of WccAdf.ear"
cp -v /$vol_name/oracle/wccontent/wccadf/WccAdf.ear /$vol_name/oracle/wccontent/wccadf/WccAdf_original.ear
echo " Extracting the ear file WccAdf.ear"
mkdir -pv /$vol_name/oracle/wccontent/wccadf/WCCADF_EAR
cd /$vol_name/oracle/wccontent/wccadf/WCCADF_EAR
jar -xvf /$vol_name/oracle/wccontent/wccadf/WccAdf.ear
cd /$vol_name/oracle/wccontent/wccadf/WCCADF_EAR/adf/META-INF
echo " Replacing the values in connections.xml"
echo " Hostname = $HOSTNAME"
echo " Intra doc port = $UCM_INTRADOC_PORT"
sed -i "s/localhost/$HOSTNAME/g" connections.xml
sed -i "s/4444/$UCM_INTRADOC_PORT/g" connections.xml
echo " Recreating the WccAdf.ear"
cd ../..
jar -cvf WccAdf.ear .
echo " Moving WccAdf.ear to right place"
cp -vf WccAdf.ear /$vol_name/oracle/wccontent/wccadf/WccAdf.ear
cd ..
rm -rvf /$vol_name/oracle/wccontent/wccadf/WCCADF_EAR

#start WCCADF Server
sh /$vol_name/oracle/container-scripts/startManagedServer.sh $server


export servers=WCCADF
echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $hostname $servers
fi

