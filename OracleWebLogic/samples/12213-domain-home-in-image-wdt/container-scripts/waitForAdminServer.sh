#!/bin/bash
#
#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# This script will wait until Admin Server is available.
# There is no timeout!
#
echo "Waiting for WebLogic Admin Server on $ADMIN_HOST:$ADMIN_PORT to become available..."
while :
do
  (echo > /dev/tcp/$ADMIN_HOST/$ADMIN_PORT) >/dev/null 2>&1
  available=$?
  if [[ $available -eq 0 ]]; then
    echo "WebLogic Admin Server is now available. Proceeding..."
    break
  fi
  sleep 1
done
