#!/bin/bash
# shellcheck disable=SC2034,SC2166,SC2155,SC1090,SC2046,SC2178,SC2207,SC2163,SC2115,SC2173,SC1091,SC1143,SC2164,SC3014
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2021 Oracle and/or its affiliates.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Setup the Linux kernel parameter inside the container. Note that some parameter need to be set on container  host.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

if ls $GRID_HOME/cv/rpm/cvuqdisk* > /dev/null 2>&1; then
  rpm -Uvh "$GRID_HOME/cv/rpm/cvuqdisk*"
fi 
#echo "ulimit -S -s 10240" >> /home/grid/.bashrc
#echo "ulimit -S -s 10240" >> /home/oracle/.bashrc
