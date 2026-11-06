#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates.
#
# Description: Runs startup smoke tests for Oracle AI Database 26ai containers
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source ./helperFunctions.sh

runContainerTest "23.26.0 EE default database" "23.26.0-EE-default" "oracle/database:23.26.0-ee"
runContainerTest "23.26.0 SE2 default database" "23.26.0-SE2-default" "oracle/database:23.26.0-se2"
runContainerTest "23.26.0 Free default database" "23.26.0-Free-default" "oracle/database:23.26.0-free" "FREE" "FREEPDB1"
