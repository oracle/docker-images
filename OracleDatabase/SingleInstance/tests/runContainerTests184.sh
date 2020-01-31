#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: December, 2018
# Author: gerald.venzl@oracle.com
# Description: Runs all 18c XE related tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source ./helperFunctions.sh

###################### TEST 18.4.0 XE default ###########################

runContainerTest "18.4.0 XE default database" "18.4.0-XE-default" "oracle/database:18.4.0-xe" "XE" "XEPDB1"

###################### TEST 18.4.0 EE WE8ISO8859P1 character set ###########################

runContainerTest "18.4.0 XE WE8ISO8859P1 character set" "18.4.0-XE-WE8ISO8859P1-character-set" "oracle/database:18.4.0-xe" "XE" "XEPDB1" "WE8ISO8859P1"

###################### TEST 18.4.0 EE WE8MSWIN1252 character set ###########################

runContainerTest "18.4.0 XE WE8MSWIN1252 character set" "18.4.0-XE-WE8MSWIN1252-character-set" "oracle/database:18.4.0-xe" "XE" "XEPDB1" "WE8MSWIN1252"

###################### TEST 18.4.0 EE JA16SJISTILDE character set ###########################

runContainerTest "18.4.0 XE JA16SJISTILDE character set" "18.4.0-EE-JA16SJISTILDE-character-set" "oracle/database:18.4.0-xe" "XE" "XEPDB1" "JA16SJISTILDE"

