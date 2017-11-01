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

Usage: buildDockerImage.sh [-i] [-o] [Docker build option]
Builds a Docker Image for Oracle Rest Data Services
  
Parameters:
   -i: ignores the MD5 checksums
   -o: passes on Docker build option

LICENSE UPL 1.0

Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

EOF
  exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum.$VERSION
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder '$VERSION'."
    exit $?
  fi
}

# Parameters
VERSION=""
SKIPMD5=0
DOCKEROPS=""

while getopts "hio:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "i")
      SKIPMD5=1
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

# Determine latest version
# Do this after the options so that users can still do a "-h"
if [ `ls -al ords*zip 2>/dev/null | wc -l` -gt 1 ]; then
  echo "ERROR: Found multiple versions of ORDS zip files.";
  echo "ERROR: Please only put one ORDS zip file into this directory!";
  exit 1;
else
  VERSION=$(ls ords*zip 2>/dev/null | awk 'match ($0, /(ords\.)(.{1,2}\..{1,2}\..{1,2})\.(.+.zip)/, result) { print result[2] }')
fi;

if [ -z "$VERSION" ]; then
  echo "ERROR: No install file is in this directory!"
  echo "ERROR: Please copy the install file into this directory or refer to the ReadMe!"
  exit 1;
fi;


# Oracle Database Image Name
IMAGE_NAME="oracle/restdataservices:$VERSION"

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

