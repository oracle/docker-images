#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
# 
# Since: August, 2017
# Author: gerald.venzl@oracle.com
# Description: Runs all tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

./runContainerTests23260.sh || exit $?
./runContainerTests213.sh || exit $?
./runContainerTests193.sh || exit $?
./runContainerTests122.sh || exit $?
./runContainerTests121.sh || exit $?
