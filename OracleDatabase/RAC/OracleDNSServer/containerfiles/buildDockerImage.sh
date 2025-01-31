#!/bin/bash
# LICENSE UPL 1.0
# 
# Since: January, 2018
# Author: Paramdeep saini <paramdeep.saini@oracle.com>
# Description: Build script for building Oracle RAC Storage Server Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
  cat << EOF

Usage: buildDockerImage.sh -v [version] [-o] [Docker build option]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -o: passes on Docker build option

LICENSE UPL 1.0

Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

EOF
  exit 0
}

##############
#### MAIN ####
##############

# Parameters
VERSION="12.2.0.1"
SKIPMD5=0
DOCKEROPS=""

while getopts "hiv:o:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "o")
      DOCKEROPS="$OPTARG"
      ;;
    "?")
      usage;
      exit 1;
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# Oracle Database Image Name
IMAGE_NAME="oracle/rac-dns-server:$VERSION"

# Go into version folder
cd $VERSION

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
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle RAC Storage Server Docker Image version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

else
  echo "Oracle RAC Storage Server Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

