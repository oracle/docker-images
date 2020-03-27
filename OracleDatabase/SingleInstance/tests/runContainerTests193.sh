#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates.
# 
# Since: March, 2020
# Author: gerald.venzl@oracle.com
# Description: Runs all 19c related tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source ./helperFunctions.sh

###################### TEST 19.3.0 EE default ###########################

runContainerTest "19.3.0 EE default database" "19.3.0-EE-default" "oracle/database:19.3.0-ee"

###################### TEST 19.3.0 SE2 default ###########################

runContainerTest "19.3.0 SE2 default database" "19.3.0-SE2-default" "oracle/database:19.3.0-se2"

###################### TEST 19.3.0 EE lowercase PDB name ###########################

runContainerTest "19.3.0 EE lowercase PDB name" "19.3.0-EE-lowercase-pdb" "oracle/database:19.3.0-ee" "ORCLTEST" "mypdb"

###################### TEST 19.3.0 EE WE8ISO8859P1 character set ###########################

runContainerTest "19.3.0 EE WE8ISO8859P1 character set" "19.3.0-EE-WE8ISO8859P1-character-set" "oracle/database:19.3.0-ee" "ORCLTEST" "PDB1" "WE8ISO8859P1"

###################### TEST 19.3.0 EE WE8MSWIN1252 character set ###########################

runContainerTest "19.3.0 EE WE8MSWIN1252 character set" "19.3.0-EE-WE8MSWIN1252-character-set" "oracle/database:19.3.0-ee" "ORCLTEST" "PDB1" "WE8MSWIN1252"

###################### TEST 19.3.0 EE JA16SJISTILDE character set ###########################

runContainerTest "19.3.0 EE JA16SJISTILDE character set" "19.3.0-EE-JA16SJISTILDE-character-set" "oracle/database:19.3.0-ee" "ORCLTEST" "PDB1" "JA16SJISTILDE"

###################### TEST 19.3.0 EE KO16KSC5601 character set ###########################

runContainerTest "19.3.0 EE KO16KSC5601 character set" "19.3.0-EE-KO16KSC5601-character-set" "oracle/database:19.3.0-ee" "ORCLTEST" "PDB1" "KO16KSC5601"

###################### TEST 19.3.0 EE lowercase ORACLE_SID ###########################

runContainerTest "19.3.0 EE lowercase ORACLE_SID" "19.3.0-EE-lowercase_ORACLE_SID" "oracle/database:19.3.0-ee" "orcltest" "PDB1"

###################### TEST 19.3.0 EE lowercase ORACLE_PDB ###########################

runContainerTest "19.3.0 EE lowercase ORACLE_PDB" "19.3.0-EE-lowercase_ORACLE_PDB" "oracle/database:19.3.0-ee" "ORCLTEST" "pdb1"
