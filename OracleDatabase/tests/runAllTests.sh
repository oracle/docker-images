#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
# 
# Since: June, 2017
# Author: gerald.venzl@oracle.com
# Description: Runs all tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

WORKDIR=$PWD;
BIN_DIR=$WORKDIR

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
  ORACLE_SID={$4:-ORCLCDB}

  # Run and start container
  docker run -d -e ORACLE_SID=$ORACLE_SID --name $CON_NAME $IMAGE
  
  # Check whether Oracle is OK
  checkOracle "$TEST_NAME" $CON_NAME $ORACLE_SID
  testOK=$?
  
  docker kill $CON_NAME
  docker rm -v $CON_NAME
  
  checkError "$TEST_NAME" $testOK
}

# Function: checkError
# Checks command result for errors
# Parameter:
# TEST_NAME: The test name
# RETURN_CODE: The return code of the other command

function checkError {
  TEST_NAME="$1"
  RETURN_CODE="$2"

  if [ "$RETURN_CODE" != "0" ]; then
    echo "Test $TEST_NAME: FAILED!";
    cleanup;
    exit 1;
  else
    echo "Test $TEST_NAME: OK";
    return 0;
  fi;
}

# Function: cleanup
# Cleans up the test directory
function cleanup {
  rm ./*/*.zip
  cd $WORKDIR
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
    docker logs $CON_NAME | grep 'DATABASE IS READY TO USE' >/dev/null
    if [ $? == 0 ]; then
      return 0;
    fi;
    
    # Did something go wrong?
    docker logs $CON_NAME | grep 'DATABASE SETUP WAS NOT SUCCESSFUL' >/dev/null
    if [ $? == 0 ]; then
      return 1;
    fi;
    
  done;
}

cd ../dockerfiles

###################### TEST ###########################

# Copy binary file
cp $BIN_DIR/oracle-xe-11.2.0-1.0.x86_64.rpm.zip ./11.2.0.2/

# Build 11.2.0.2 XE images
./buildDockerImage.sh -x -v 11.2.0.2
checkError "Build 11.2.0.2 XE image" $?

# Delete binary file
rm ./11.2.0.2/oracle-xe-11.2.0-1.0.x86_64.rpm.zip

###################### TEST ###########################

# Copy binary file
cp $BIN_DIR/linuxamd64_12102_database_se2_*.zip ./12.1.0.2/

# Build 12.1.0.2 SE2 images
./buildDockerImage.sh -s -v 12.1.0.2
checkError "Build 12.1.0.2 SE2 image" $?

# Delete binary file
rm ./12.1.0.2/*.zip

###################### TEST ###########################

# Copy binary file
cp $BIN_DIR/linuxamd64_12102_database_1of2.zip ./12.1.0.2/
cp $BIN_DIR/linuxamd64_12102_database_2of2.zip ./12.1.0.2/

# Build 12.1.0.2 EE images
./buildDockerImage.sh -e -v 12.1.0.2
checkError "Build 12.1.0.2 EE image" $?

# Delete binary file
rm ./12.1.0.2/*.zip

###################### TEST ###########################

# Copy binary file
cp $BIN_DIR/linuxx64_12201_database.zip ./12.2.0.1/

# Build 12.2.0.1 SE2 images
./buildDockerImage.sh -s -v 12.2.0.1
checkError "Build 122.0.1 SE2 image" $?

###################### TEST ###########################

# Build 12.2.0.1 EE images
./buildDockerImage.sh -e -v 12.2.0.1
checkError "Build 12.2.0.1 EE image" $?

rm ./12.2.0.1/*.zip

###################### TEST ###########################

# Run 12.1.0.2 SE2 default container
runContainerTest "12.1.0.2 SE2 default database" "12.1.0.2-SE2-default" "oracle/database:12.1.0.2-se2"

###################### TEST ###########################

# Run 12.1.0.2 EE default container
runContainerTest "12.1.0.2 EE default database" "12.1.0.2-EE-default" "oracle/database:12.1.0.2-ee"

###################### TEST ###########################

# Run 12.2.0.1 SE2 default container
runContainerTest "12.2.0.1 SE2 default database" "12.2.0.1-SE2-default" "oracle/database:12.2.0.1-se2"

###################### TEST ###########################

# Run 12.2.0.1 EE default container
runContainerTest "12.2.0.1 EE default database" "12.2.0.1-EE-default" "oracle/database:12.2.0.1-ee"

###################### TEST ###########################

# Run 12.2.0.1 EE custom container
runContainerTest "12.2.0.1-EE-custom database" "12.2.0.1-EE-custom" "oracle/database/12.2.0.1-ee" "TEST"

# Run 12.2.0.1 EE custom characterset
