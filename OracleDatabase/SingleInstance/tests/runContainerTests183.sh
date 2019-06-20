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

runContainerTest "18.3.0 EE default database" "18.3.0-EE-default" "oracle/database:18.3.0-ee"

###################### TEST 18.3.0 SE2 default ###########################

runContainerTest "18.3.0 SE2 default database" "18.3.0-SE2-default" "oracle/database:18.3.0-se2"

###################### TEST 18.3.0 EE lowercase PDB name ###########################

runContainerTest "18.3.0 EE lowercase PDB name" "18.3.0-EE-lowercase-pdb" "oracle/database:18.3.0-ee" "ORCLTEST" "mypdb"

###################### TEST 18.3.0 EE WE8ISO8859P1 character set ###########################

runContainerTest "18.3.0 EE WE8ISO8859P1 character set" "18.3.0-EE-WE8ISO8859P1-character-set" "oracle/database:18.3.0-ee" "ORCLTEST" "PDB1" "WE8ISO8859P1"

###################### TEST 18.3.0 EE WE8MSWIN1252 character set ###########################

runContainerTest "18.3.0 EE WE8MSWIN1252 character set" "18.3.0-EE-WE8MSWIN1252-character-set" "oracle/database:18.3.0-ee" "ORCLTEST" "PDB1" "WE8MSWIN1252"

###################### TEST 18.3.0 EE JA16SJISTILDE character set ###########################

runContainerTest "18.3.0 EE JA16SJISTILDE character set" "18.3.0-EE-JA16SJISTILDE-character-set" "oracle/database:18.3.0-ee" "ORCLTEST" "PDB1" "JA16SJISTILDE"

###################### TEST 18.3.0 EE KO16KSC5601 character set ###########################

runContainerTest "18.3.0 EE KO16KSC5601 character set" "18.3.0-EE-KO16KSC5601-character-set" "oracle/database:18.3.0-ee" "ORCLTEST" "PDB1" "KO16KSC5601"

###################### TEST 18.3.0 EE lowercase ORACLE_SID ###########################

runContainerTest "18.3.0 EE lowercase ORACLE_SID" "18.3.0-EE-lowercase_ORACLE_SID" "oracle/database:18.3.0-ee" "orcltest" "PDB1"

###################### TEST 18.3.0 EE lowercase ORACLE_PDB ###########################

runContainerTest "18.3.0 EE lowercase ORACLE_PDB" "18.3.0-EE-lowercase_ORACLE_PDB" "oracle/database:18.3.0-ee" "ORCLTEST" "pdb1"
