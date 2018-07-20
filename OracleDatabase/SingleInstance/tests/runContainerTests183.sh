#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2018
# Author: gerald.venzl@oracle.com
# Description: Runs all 18c related tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source ./helperFunctions.sh

###################### TEST 18.3.0 EE default ###########################

# Run 18.3.0 EE default container
runContainerTest "18.3.0 EE default database" "18.3.0-EE-default" "oracle/database:18.3.0-ee"

###################### TEST 18.3.0 SE2 default ###########################

# Run 18.3.0 SE2 default container
runContainerTest "18.3.0 SE2 default database" "18.3.0-SE2-default" "oracle/database:18.3.0-se2"

###################### TEST 18.3.0 EE lowercase PDB name ###########################

# Run 18.3.0 EE lowercase PDB name
runContainerTest "18.3.0 EE lowercase PDB name" "18.3.0-EE-lowercase-pdb" "oracle/database:18.3.0-ee" "ORCLTEST" "mypdb"

