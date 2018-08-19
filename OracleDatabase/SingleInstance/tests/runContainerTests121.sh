#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2018
# Author: gerald.venzl@oracle.com
# Description: Runs all 12cR1 related tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source ./helperFunctions.sh

###################### TEST 12.1.0.2 EE lowercase PDB name ###########################

# Run 12.1.0.2 EE lowercase PDB name
runContainerTest "12.1.0.2 EE lowercase PDB name" "12.1.0.2-EE-lowercase-pdb" "oracle/database:12.1.0.2-ee" "ORCLTEST" "mypdb"

###################### TEST 12.1.0.2 EE default ###########################

# Run 12.1.0.2 EE default container
runContainerTest "12.1.0.2 EE default database" "12.1.0.2-EE-default" "oracle/database:12.1.0.2-ee"

###################### TEST 12.1.0.2 SE2 default ###########################

# Run 12.1.0.2 SE2 default container
runContainerTest "12.1.0.2 SE2 default database" "12.1.0.2-SE2-default" "oracle/database:12.1.0.2-se2"
