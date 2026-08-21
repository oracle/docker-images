#!/bin/bash
#
# LICENSE UPL 1.0
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description: 
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#

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
