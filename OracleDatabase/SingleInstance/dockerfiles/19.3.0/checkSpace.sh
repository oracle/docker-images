#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the available space of the system.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

REQUIRED_SPACE_GB=18
AVAILABLE_SPACE_GB=`df -PB 1G / | tail -n 1 | awk '{ print $4 }'`

if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
  script_name=`basename "$0"`
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "$script_name: ERROR - There is not enough space available in the docker container."
  echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB, but only $AVAILABLE_SPACE_GB GB are available."
  echo "If needed, you can increase the size limit in dockerd using \`--storage-opt dm.basesize=$((REQUIRED_SPACE_GB+1))G -s devicemapper'"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1;
fi;
