#!/bin/bash -e
# 
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Build script for building Docker Image Extensions
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
# 

SCRIPT_DIR=$(dirname $0)
SCRIPT_NAME=$(basename $0)

usage() {
  cat << EOF

Usage: $SCRIPT_NAME -a -x [extensions] -b [base image]  -t [image name] [-o] [Docker build option]
Builds one of more Docker Image Extensions.
  
Parameters:
   -a: Build all extensions
   -x: Space separated extensions to build. Defaults to all
       Choose from : $(for i in $(cd "$SCRIPT_DIR" && ls -d */); do echo -n "${i%%/}  "; done)
   -b: Base image to use
   -t: name:tag for the extended image
   -o: passes on Docker build option

LICENSE UPL 1.0

Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.

EOF

}

##############
#### MAIN ####
##############

# Parameters
DOCKEROPS=""
DOCKERFILE="Dockerfile"
BASE_IMAGE="oracle/database:19.3.0-ee"
IMAGE_NAME="oracle/database:ext"

if [ "$#" -eq 0 ]; then
  usage;
  exit 1;
fi

while getopts "ax:b:t:o:h" optname; do
  case "$optname" in
    a)
      EXTENSIONS=$(for i in $(cd "$SCRIPT_DIR" && ls -d */); do echo -n "${i%%/}  "; done)
      ;;
    x)
      EXTENSIONS="$OPTARG"
      ;;
    b)
      BASE_IMAGE="$OPTARG"
      ;;
    t)
      IMAGE_NAME="$OPTARG"
      ;;
    o)
      DOCKEROPS="$OPTARG"
      ;;
    h|?)
      usage;
      exit 1;
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

echo "=========================="
echo "DOCKER info:"
docker info
echo "=========================="

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
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #

BUILD_START=$(date '+%s')

cd "$SCRIPT_DIR"
for x in $EXTENSIONS; do
  echo "Building extension $x..."
  # Go into version folder
  cd "$x" || {
    echo "Could not find extension directory '$x'";
    exit 1;
  }
  docker build --force-rm=true --build-arg BASE_IMAGE="$BASE_IMAGE" \
       $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f $DOCKERFILE . || {
  echo ""
  echo "ERROR: Oracle Database Docker Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the docker build operation."
  exit 1
  }
  BASE_IMAGE="$IMAGE_NAME"
  cd ..
done

# Remove dangling images (intermitten images with tag <none>)
docker image prune -f > /dev/null

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo ""

cat<<EOF
  Oracle Database Docker Image extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
