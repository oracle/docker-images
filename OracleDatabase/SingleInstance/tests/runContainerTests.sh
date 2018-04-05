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

# Function: runContainerTest
# Runs a specific test
# Parameters:
# TEST_NAME: The test name
# CON_NAME: The container name
# IMAGE: The image to use
# ORACLE_SID: The Oracle SID
function runContainerTest {
  TEST_NAME="$1"
  CON_NAME="$2"
  IMAGE="$3"
  ORACLE_SID=${4:-ORCLTEST}
  ORACLE_PDB=${5:-ORCLPDBTEST}

  echo "Test: $TEST_NAME"
  echo ""
  
  # Run and start container
  docker run -d --shm-size=1g -e ORACLE_SID="$ORACLE_SID" -e ORACLE_PDB="$ORACLE_PDB" --name "$CON_NAME" "$IMAGE"
  
  # Check whether Oracle is OK
  checkOracle "$TEST_NAME" "$CON_NAME" "$ORACLE_SID"
  TEST_OK=$?
  
  docker kill "$CON_NAME"
  docker rm -v "$CON_NAME"
  
  if [ "$TEST_OK" != "0" ]; then
    # Print logs of failed test
    docker logs $CON_NAME;
    echo "";
    echo "Test $TEST_NAME: FAILED!";
    echo "";
    exit 1;
  else
    echo "Test $TEST_NAME: OK";
    echo "";
    return 0;
  fi;

}

# Function: checkOracle
# Checks whether Oracle DB is up and running
# Parameters:
# TEST_NAME: The test name
# CON_NAME: The container name
# ORACLE_SID: Oracle DB SID

function checkOracle {
  TEST_NAME="$1"
  CON_NAME="$2"
  ORACLE_SID="$3"
  
  # Wait until container is ready
  while true; do
    # Sleep for a while to give the container time to create the db
    sleep 15;
    
    # Is the database ready to be used?
    docker logs $CON_NAME | grep 'DATABASE IS READY TO USE' >/dev/null;
    if [ "$?" == "0" ]; then
      return 0;
    fi;
    
    docker logs $CON_NAME | grep 'DATABASE SETUP WAS NOT SUCCESSFUL' >/dev/null;
    # Did something go wrong?
    if [ "$?" == "0" ]; then
      return 1;
    fi;
    
  done;
}

###################### TEST 12.2.0.2 EE lowercase PDB name ###########################

# Run 12.2.0.1 EE lowercase PDB name
runContainerTest "12.2.0.1 EE lowercase PDB name" "12.2.0.1-EE-lowercase-pdb" "oracle/database:12.2.0.1-ee" "ORCLTEST" "mypdb"

###################### TEST 12.1.0.2 EE lowercase PDB name ###########################

# Run 12.1.0.2 EE lowercase PDB name
runContainerTest "12.1.0.2 EE lowercase PDB name" "12.1.0.2-EE-lowercase-pdb" "oracle/database:12.1.0.2-ee" "ORCLTEST" "mypdb"

###################### TEST 11.2.0.2 XE default ###########################

# Run 11.2.0.2 XE default container
runContainerTest "11.2.0.2 XE default database" "11.2.0.2-XE-default" "oracle/database:11.2.0.2-xe" "XE"

###################### TEST 12.2.0.1 EE default ###########################

# Run 12.2.0.1 EE default container
runContainerTest "12.2.0.1 EE default database" "12.2.0.1-EE-default" "oracle/database:12.2.0.1-ee"

###################### TEST 12.2.0.1 EE custom DB ###########################

# Run 12.2.0.1 EE custom container
runContainerTest "12.2.0.1-EE-custom database" "12.2.0.1-EE-custom" "oracle/database:12.2.0.1-ee" "TEST"

###################### TEST 12.2.0.1 SE2 default ###########################

# Run 12.2.0.1 SE2 default container
runContainerTest "12.2.0.1 SE2 default database" "12.2.0.1-SE2-default" "oracle/database:12.2.0.1-se2"

###################### TEST 12.1.0.2 EE default ###########################

# Run 12.1.0.2 EE default container
runContainerTest "12.1.0.2 EE default database" "12.1.0.2-EE-default" "oracle/database:12.1.0.2-ee"

###################### TEST 12.1.0.2 SE2 default ###########################

# Run 12.1.0.2 SE2 default container
runContainerTest "12.1.0.2 SE2 default database" "12.1.0.2-SE2-default" "oracle/database:12.1.0.2-se2"
