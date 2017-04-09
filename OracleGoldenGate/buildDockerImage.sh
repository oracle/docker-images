#!/bin/bash
#
# Since: April, 2016
# Author: rick.michaud@oracle.com
# Description: Build script for building Oracle Database Docker images.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#

IMAGE_NAME="ogg-oracle:12.1.0.2-ee"

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle GoldenGate and Database Docker Image for is ready :

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF

else
  echo "Oracle Database Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

