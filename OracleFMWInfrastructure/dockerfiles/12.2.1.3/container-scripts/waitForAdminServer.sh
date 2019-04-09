#!/bin/bash
#
#Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# This script will wait until Admin Server is available.
# There is no timeout!
#
if [ ${ADMINISTRATION_PORT_ENABLED} == "true" ]
then
 connectString="${ADMIN_HOST}/${ADMINISTRATION_PORT}"
else
 connectString="${ADMIN_HOST}/${ADMIN_LISTEN_PORT}"
fi 

echo "Waiting for WebLogic Admin Server on ${connectString} to become available..."
while :
do
  (echo > /dev/tcp/${connectString}) >/dev/null 2>&1
  available=$?
  if [[ $available -eq 0 ]]; then
    echo "WebLogic Admin Server is now available. Proceeding..."
    break
  fi
  sleep 1
done
