#!/bin/bash
# 
# Since: October, 2016
# Author: Jonathan Knight
# Description: script to build a Docker image 
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2016 Oracle and/or its affiliates. All rights reserved.
# 

# Image Name
IMAGE_NAME="oracle/coherence-jmx-example:1.0"

echo "====================="

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME'..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true -t ${IMAGE_NAME} -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr ${BUILD_END} - ${BUILD_START}`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Coherence Docker Image is ready to be used:
    
    --> ${IMAGE_NAME}

  Build completed in ${BUILD_ELAPSED} seconds.

EOF
else
  echo "Coherence Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
