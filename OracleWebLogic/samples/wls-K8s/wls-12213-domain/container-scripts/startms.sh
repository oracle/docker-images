#! /usr/bin/bash

#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start Managed Servers in the cluster

domain_home=${DOMAINS_DIR}/${DOMAIN_NAME}
ms_name_from_image=${DEFAULT_MS_NAME}

# Update wldf action with operator endpoint url
sed -i 's/${OPERATOR_ENDPOINT}/'${OPERATOR_ENDPOINT}'/' $domain_home/config/diagnostics/Module-0-3905.xml
chmod +w $domain_home/config/diagnostics/Module-0-3905.xml

# Cluster Info
export CLUSTER_NAME=DockerCluster
export KEY_CLUSTER_PREFIX=${CLUSTER_NAME}/
# Concurrency Lock Info
export LOCK_NAME=Lock-${CLUSTER_NAME}
# Stores Managed Server Name
#export LOCAL_MS_NAME_PIPE=/tmp/MSName.fifo
export SITUATIONAL_CONFIG_DIR=${domain_home}/optconfig
mkdir $SITUATIONAL_CONFIG_DIR

#If this file exist, then this MS is done
export MS_DONE_FILE=/tmp/MSCompleted.dat

#echo "Generate MS Name and start etcd watch"
#$(dirname $0)/generate-ms-name.sh
# Read the MS Name from Pipe
#read LOCAL_MS_NAME <${LOCAL_MS_NAME_PIPE}
#rm -f $LOCAL_MS_NAME_PIPE

echo "Launching with parameters"
echo "Domain Home: " $domain_home
echo "MS Name from Image: " $ms_name_from_image

cd $domain_home

# use pod name as local ms name
export LOCAL_MS_NAME=${MY_POD_NAME}

# Rename the server directory
if [ "$ms_name_from_image" != "$LOCAL_MS_NAME" ]; then
  echo "Setting up server name as $LOCAL_MS_NAME"
  mv servers/$ms_name_from_image servers/$LOCAL_MS_NAME
fi

# Relays SIGTERM to all java processes
function relay_SIGTERM {
  pid=`grep java /proc/[0-9]*/comm | awk -F / '{ print $3; }'`
  echo "Sending SIGTERM to java process " $pid
  kill -SIGTERM $pid
}

trap relay_SIGTERM SIGTERM

# Start server
(bin/startManagedWebLogic.sh $LOCAL_MS_NAME t3://wls-admin-server:8001 ) &

while [ ! -f $MS_DONE_FILE ]
do
  tail -f /dev/null & wait ${!}
done
