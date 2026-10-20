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


cd "../dockerfiles" || exit

###################### TESTS 23.26.0 images ###########################

cp "$BIN_DIR/LINUX.X64_2326000_db_home.zip" ./23.26.0/ || exit

# Skip checksum validation until the 26ai checksum files are populated.
./buildContainerImage.sh -i -e -v 23.26.0
checkError "Build 23.26.0 EE image" $?

./buildContainerImage.sh -i -s -v 23.26.0
checkError "Build 23.26.0 SE2 image" $?

rm ./23.26.0/LINUX.X64_2326000_db_home.zip

./buildContainerImage.sh -f -v 23.26.0
checkError "Build 23.26.0 Free image" $?

###################### TESTS 21.3.0 images ###########################

cp "$BIN_DIR/LINUX.X64_213000_db_home.zip" ./21.3.0/ || exit

./buildContainerImage.sh -e -v 21.3.0
checkError "Build 21.3.0 EE image" $?

./buildContainerImage.sh -s -v 21.3.0
checkError "Build 21.3.0 SE2 image" $?

rm ./21.3.0/LINUX.X64_213000_db_home.zip

./buildContainerImage.sh -x -v 21.3.0
checkError "Build 21.3.0 XE image" $?

###################### TESTS 19.3.0 images ###########################

# Copy binary file
cp "$BIN_DIR/LINUX.X64_193000_db_home.zip" ./19.3.0/ || exit

###################### TEST 19.3.0 EE ###########################

# Build 19.3.0 EE images
./buildContainerImage.sh -e -v 19.3.0
checkError "Build 19.3.0 EE image" $?

###################### TEST 19.3.0 SE2 ###########################

# Build 19.3.0 SE2 images
./buildContainerImage.sh -s -v 19.3.0
checkError "Build 19.3.0 SE2 image" $?

# Delete binary file
rm ./19.3.0/LINUX.X64_193000_db_home.zip

###################### END TESTS 19.3.0 images ###########################


###################### TEST 12.2.0.1 EE ###########################

# Copy binary file
cp "$BIN_DIR/linuxx64_12201_database.zip" ./12.2.0.1/ || exit

# Build 12.2.0.1 EE images
./buildContainerImage.sh -e -v 12.2.0.1
checkError "Build 12.2.0.1 EE image" $?

###################### TEST 12.2.0.1 SE2 ###########################

# Build 12.2.0.1 SE2 images
./buildContainerImage.sh -s -v 12.2.0.1
checkError "Build 12.2.0.1 SE2 image" $?

rm ./12.2.0.1/*.zip

###################### TEST 12.1.0.2 EE ###########################

# Copy binary file
cp "$BIN_DIR/linuxamd64_12102_database_1of2.zip" ./12.1.0.2/ || exit
cp "$BIN_DIR/linuxamd64_12102_database_2of2.zip" ./12.1.0.2/ || exit

# Build 12.1.0.2 EE images
./buildContainerImage.sh -e -v 12.1.0.2
checkError "Build 12.1.0.2 EE image" $?

# Delete binary file
rm ./12.1.0.2/*.zip

###################### TEST 12.1.0.2 SE2 ###########################

# Copy binary file
cp "$BIN_DIR"/linuxamd64_12102_database_se2_*.zip ./12.1.0.2/ || exit

# Build 12.1.0.2 SE2 images
./buildContainerImage.sh -s -v 12.1.0.2
checkError "Build 12.1.0.2 SE2 image" $?

# Delete binary file
rm ./12.1.0.2/*.zip

######################### END OF TESTS ############################

cd "$WORKDIR" || exit
