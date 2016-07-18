#!/bin/bash
# 
# Since: April, 2016
# Author: gerald.venzl@oracle.com
# Description: Build script for building Oracle Database Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-p] [-i]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -e: creates image based on 'Enterprise Edition'
   -s: creates image based on 'Standard Edition 2'
   -x: creates image based on 'Express Edition'
   -p: password for database admin accounts (it will be generated if omitted)
   -i: ignores the MD5 checksums

* select one edition only: -e, -s, or -x

LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum.$EDITION
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION."
    exit $?
  fi
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
ENTERPRISE=0
STANDARD=0
EXPRESS=0
VERSION="12.1.0.2"
SKIPMD5=0
DOCKEROPS=""
ORACLE_PWD=""
GENERATED_PWD=1

while getopts "hesxiv:p:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "i")
      SKIPMD5=1
      ;;
    "e")
      ENTERPRISE=1
      ;;
    "s")
      STANDARD=1
      ;;
    "x")
      EXPRESS=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "p")
      ORACLE_PWD="$OPTARG"
      GENERATED_PWD=0
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# Which Edition should be used?
if [ $((ENTERPRISE + STANDARD + EXPRESS)) -gt 1 ]; then
  usage
elif [ $ENTERPRISE -eq 1 ]; then
  EDITION="ee"
elif [ $STANDARD -eq 1 ]; then
  EDITION="se2"
elif [ $EXPRESS -eq 1 ] && [ "$VERSION" = "12.1.0.2" ]; then
  echo "Version 12.1.0.2 does not have Express Edition available."
  exit 1
else
  EDITION="xe";
  DOCKEROPS="--shm-size=1G";
fi

# Is password omitted?
if [ "$GENERATED_PWD" -eq 1 ]; then
   ORACLE_PWD="`pwmake 64`";
fi

# Oracle Database Image Name
IMAGE_NAME="oracle/database:$VERSION-$EDITION"

# Go into version folder
cd $VERSION

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Ignored MD5 checksum."
fi

echo "====================="

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg=\"http_proxy=${http_proxy}\""
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg=\"https_proxy=${https_proxy}\""
fi

if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg=\"ftp_proxy=${ftp_proxy}\""
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg=\"no_proxy=${no_proxy}\""
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
docker build --build-arg ORACLE_PWD=$ORACLE_PWD --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile.$EDITION . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle Database Docker Image for '$EDITION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME
    
  ORACLE PASSWORD (SYS, SYSTEM, PDBADMIN): $ORACLE_PWD

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

else
  echo "Oracle Database Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

