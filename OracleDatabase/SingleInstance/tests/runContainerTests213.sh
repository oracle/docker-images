#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates.
#
# Description: Runs startup smoke tests for Oracle Database 21c containers
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source ./helperFunctions.sh

runContainerTest "21.3.0 EE default database" "21.3.0-EE-default" "oracle/database:21.3.0-ee"
runContainerTest "21.3.0 SE2 default database" "21.3.0-SE2-default" "oracle/database:21.3.0-se2"
runContainerTest "21.3.0 XE default database" "21.3.0-XE-default" "oracle/database:21.3.0-xe" "XE" "XEPDB1"
