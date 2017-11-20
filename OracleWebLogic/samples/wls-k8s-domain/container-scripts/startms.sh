#!/bin/bash

#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start Managed Servers in the cluster

echo "Waiting for admin server ready"
maxRetry=60
count=1
ok=0

# wait until domain provision finished or exit after max retry
while [ $ok -lt 1 -a $count -lt $maxRetry ] ; do
  sleep 5 
  ok=`curl -I -v \
  --user $WLUSER:$WLPASSWORD \
  -H X-Requested-By:MyClient \
  -H Accept:application/json \
  -X GET http://admin-server:$ADMIN_PORT/management/weblogic/latest/domainConfig/servers/managed-server-3 | grep -c 'HTTP/1.1 200'`
  echo "ok is ${ok}, iteration $count of $maxRetry"
  count=`expr $count + 1`
done
if [ ${ok:=Error} == 0 ] ; then
  echo "ERROR: domain is not ready, exiting!"
  exit 1
fi

mkdir -p $SAMPLE_DOMAIN_HOME/servers/$MY_POD_NAME/security && \
cp $SAMPLE_DOMAIN_HOME/servers/AdminServer/security/boot.properties $SAMPLE_DOMAIN_HOME/servers/$MY_POD_NAME/security/boot.properties

. $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh
cd $SAMPLE_DOMAIN_HOME
bin/startManagedWebLogic.sh $MY_POD_NAME t3://admin-server:$ADMIN_PORT
