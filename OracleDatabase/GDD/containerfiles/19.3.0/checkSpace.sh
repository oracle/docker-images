#!/bin/bash
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# MAINTAINER <paramdeep.saini@oracle.com>

REQUIRED_SPACE_GB=2
AVAILABLE_SPACE_GB=`df -PB 1G / | tail -n 1 | awk '{ print $4 }'`

if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
  script_name=`basename "$0"`
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "$script_name: ERROR - There is not enough space available in the docker container."
  echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB, but only $AVAILABLE_SPACE_GB GB are available."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1;
fi;
