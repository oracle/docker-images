#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2017
# Author: gerald.venzl@oracle.com
# Description: Runs all tests for Oracle Database Docker containers
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

WORKDIR=$PWD;
BIN_DIR=$WORKDIR/bin

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
    exit 1;
  else
    echo "Test $TEST_NAME: OK";
    return 0;
  fi;
}


cd "../dockerfiles"

###################### TEST 11.2.0.2 XE ###########################

# Copy binary file
cp $BIN_DIR/oracle-xe-11.2.0-1.0.x86_64.rpm.zip ./11.2.0.2/

# Build 11.2.0.2 XE images
./buildDockerImage.sh -x -v 11.2.0.2
checkError "Build 11.2.0.2 XE image" $?

# Delete binary file
rm ./11.2.0.2/oracle-xe-11.2.0-1.0.x86_64.rpm.zip

###################### TEST 12.2.0.1 EE ###########################

# Copy binary file
cp $BIN_DIR/linuxx64_12201_database.zip ./12.2.0.1/

# Build 12.2.0.1 EE images
./buildDockerImage.sh -e -v 12.2.0.1
checkError "Build 12.2.0.1 EE image" $?

###################### TEST 12.2.0.1 SE2 ###########################

# Build 12.2.0.1 SE2 images
./buildDockerImage.sh -s -v 12.2.0.1
checkError "Build 12.2.0.1 SE2 image" $?

rm ./12.2.0.1/*.zip

###################### TEST 12.1.0.2 EE ###########################

# Copy binary file
cp $BIN_DIR/linuxamd64_12102_database_1of2.zip ./12.1.0.2/
cp $BIN_DIR/linuxamd64_12102_database_2of2.zip ./12.1.0.2/

# Build 12.1.0.2 EE images
./buildDockerImage.sh -e -v 12.1.0.2
checkError "Build 12.1.0.2 EE image" $?

# Delete binary file
rm ./12.1.0.2/*.zip

###################### TEST 12.1.0.2 SE2 ###########################

# Copy binary file
cp $BIN_DIR/linuxamd64_12102_database_se2_*.zip ./12.1.0.2/

# Build 12.1.0.2 SE2 images
./buildDockerImage.sh -s -v 12.1.0.2
checkError "Build 12.1.0.2 SE2 image" $?

# Delete binary file
rm ./12.1.0.2/*.zip

######################### END OF TESTS ############################

cd "$WORKDIR";
