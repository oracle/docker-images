#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2018
# Author: gerald.venzl@oracle.com
# Description: Runs all 11gR2 related tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

###################### TEST 11.2.0.2 XE default ###########################

# Run 11.2.0.2 XE default container
runContainerTest "11.2.0.2 XE default database" "11.2.0.2-XE-default" "oracle/database:11.2.0.2-xe" "XE"
