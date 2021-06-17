#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

# This script will wait until Admin Server is available.
# There is no timeout!
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)
. ${SCRIPT_DIR}/_essbase-functions

echo "Waiting for WebLogic Admin Server to become available..."
while ping_adminserver ; [ $? -ne 200 ]; do
  sleep 3
done

echo "WebLogic Admin Server is now available..."
