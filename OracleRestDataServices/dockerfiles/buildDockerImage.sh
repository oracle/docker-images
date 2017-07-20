#!/bin/bash
# 
# Since: February, 2017
# Author: gerald.venzl@oracle.com
# Description: Build script for building Oracle Rest Data Services Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
  cat << EOF

Usage: buildDockerImage.sh -v [version] [-i]
Builds a Docker Image for Oracle Rest Data Services
  
Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -i: ignores the MD5 checksums

LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

EOF
  exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder '$VERSION'."
    exit $?
  fi
}

# Parameters
VERSION="3.0.10"
SKIPMD5=0
DOCKEROPS=""

while getopts "hiv:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "i")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# Oracle Database Image Name
IMAGE_NAME="oracle/restdataservices:$VERSION"

# Go into version folder
cd $VERSION

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Ignored MD5 checksum."
fi

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
  echo "Proxy settings were found and will be used during build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS \
             -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle Rest Data Services version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

else
  echo "Oracle Rest Data Services Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

