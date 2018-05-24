#! /usr/bin/bash


domain_home=${DOMAINS_DIR}/${DOMAIN_NAME}

# Update wldf action with operator endpoint url
sed -i 's/${OPERATOR_ENDPOINT}/'${OPERATOR_ENDPOINT}'/' $domain_home/config/diagnostics/Module-0-3905.xml
chmod +w $domain_home/config/diagnostics/Module-0-3905.xml

#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start the WebLogic Admin Server

# Cluster Info
export CLUSTER_NAME=DockerCluster
export KEY_CLUSTER_PREFIX=${CLUSTER_NAME}/
# Concurrency Lock Info
export LOCK_NAME=Lock-${CLUSTER_NAME}
# Stores Managed Server Name
export SITUATIONAL_CONFIG_DIR=${domain_home}/optconfig
mkdir $SITUATIONAL_CONFIG_DIR

#If this file exist, then this MS is done
export MS_DONE_FILE=/tmp/MSCompleted.dat

echo "Launching with parameters"
echo "Domain Home: " $domain_home
echo "MS Name to be used: " $LOCAL_MS_NAME
echo "MS Name to be used (from Pod name): " $MY_POD_NAME

cd $domain_home

echo "AS_NAME is '$admin_name'"

# Relays SIGTERM to all java processes
function relay_SIGTERM {
  pid=`grep java /proc/[0-9]*/comm | awk -F / '{ print $3; }'`
  echo "Sending SIGTERM to java process " $pid
  kill -SIGTERM $pid
}

trap relay_SIGTERM SIGTERM

# Start admin server
(bin/startWebLogic.sh ) &

while [ ! -f $MS_DONE_FILE ]
do
  tail -f /dev/null & wait ${!}
done
