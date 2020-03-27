#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2017, 2020 Oracle and/or its affiliates.
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

###################### TESTS 19.3.0 images ###########################

# Copy binary file
cp $BIN_DIR/LINUX.X64_193000_db_home.zip ./19.3.0/

###################### TEST 19.3.0 EE ###########################

# Build 19.3.0 EE images
./buildDockerImage.sh -e -v 19.3.0
checkError "Build 19.3.0 EE image" $?

###################### TEST 19.3.0 SE2 ###########################

# Build 19.3.0 SE2 images
./buildDockerImage.sh -s -v 19.3.0
checkError "Build 19.3.0 SE2 image" $?

# Delete binary file
rm ./19.3.0/LINUX.X64_193000_db_home.zip

###################### END TESTS 19.3.0 images ###########################


###################### TESTS 18.3.0 images ###########################

# Copy binary file
cp $BIN_DIR/LINUX.X64_180000_db_home.zip ./18.3.0/

###################### TEST 18.3.0 EE ###########################

# Build 18.3.0 EE images
./buildDockerImage.sh -e -v 18.3.0
checkError "Build 18.3.0 EE image" $?

###################### TEST 18.3.0 SE2 ###########################

# Build 18.3.0 SE2 images
./buildDockerImage.sh -s -v 18.3.0
checkError "Build 18.3.0 SE2 image" $?

# Delete binary file
rm ./18.3.0/LINUX.X64_180000_db_home.zip

###################### END TESTS 18.3.0 images ###########################


###################### TESTS 18.4.0 images ###########################

# Copy binary file
cp $BIN_DIR/oracle-database-xe-18c-1.0-1.x86_64.rpm ./18.4.0/

###################### TEST 18.4.0 XE ###########################

# Build 18.4.0 XE images
./buildDockerImage.sh -x -v 18.4.0
checkError "Build 18.4.0 XE image" $?

# Delete binary file
rm ./18.4.0/oracle-database-xe-18c-1.0-1.x86_64.rpm

###################### END TESTS 18.4.0 images ###########################


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

###################### TEST 11.2.0.2 XE ###########################

# Copy binary file
cp $BIN_DIR/oracle-xe-11.2.0-1.0.x86_64.rpm.zip ./11.2.0.2/

# Build 11.2.0.2 XE images
./buildDockerImage.sh -x -v 11.2.0.2
checkError "Build 11.2.0.2 XE image" $?

# Delete binary file
rm ./11.2.0.2/oracle-xe-11.2.0-1.0.x86_64.rpm.zip

######################### END OF TESTS ############################

cd "$WORKDIR";
