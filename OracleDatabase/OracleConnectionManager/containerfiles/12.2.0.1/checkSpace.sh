#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Checks the available space of the system.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

REQUIRED_SPACE_GB=6
AVAILABLE_SPACE_GB=`df -PB 1G / | tail -n 1 | awk '{print $4}'`

if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
  script_name=`basename "$0"`
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "$script_name: ERROR - There is not enough space available in the docker container."
  echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB , but only $AVAILABLE_SPACE_GB available."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1;
fi;
