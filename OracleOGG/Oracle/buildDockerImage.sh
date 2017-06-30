#!/bin/bash
# 
# Since: June, 2017
# Author: hadi.koesnodihardjo@oracle.com
# Description: script to build a Docker image for GoldenGate BigData
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
# 
usage() {
cat << EOF
Usage: buildDockerImage.sh -v [version] [-c]
Builds a Docker Image for Oracle GoldenGate for Oracle
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -c: enables Docker image layer cache during build
* select one distribution only: -d, -g, or -i
LICENSE CDDL 1.0 + GPL 2.0
Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
EOF
exit 0
}
if [ "$#" -eq 0 ]; then usage; fi
# Parameters
VERSION="12.2.0.1.1"
SKIPMD5=0
NOCACHE=true
while getopts "hcsdgiv:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "c")
      NOCACHE=false
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done
# GoldenGate for BigData Image Name
IMAGE_NAME="oracle/oggoracle:$VERSION"
# Go into version folder
cd $VERSION
# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi
if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi
if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi
if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi
if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during build."
fi
# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."
# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=$NOCACHE --no-cache=$NOCACHE $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`
echo ""
if [ $? -eq 0 ]; then
cat << EOF
  Oracle GoldenGate for Oracle Docker Image version $VERSION is ready to be used: 
    
    --> $IMAGE_NAME
  Build completed in $BUILD_ELAPSED seconds.
EOF
else
  echo "Oracle GoldenGate for Oracle Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
