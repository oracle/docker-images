#!/bin/bash
#
#Copyright (c) 2019, 2020, Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This script will wait until Admin Server is available.
# There is no timeout!
#
connectString="${ADMIN_HOST}/${ADMIN_LISTEN_PORT}"

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
