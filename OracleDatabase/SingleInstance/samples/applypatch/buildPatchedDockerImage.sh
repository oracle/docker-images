#!/usr/bin/env bash
# 
# Since: January, 2017
# Author: gerald.venzl@oracle.com
# Description: Shell script for applying patches to Oracle Database Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
  cat << EOF

Usage: ./buildPatchedDockerImage.sh -v [version] [-e | -s] -p [patch label]
Builds a patched Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -e: creates a patched image based on 'Enterprise Edition'
   -s: creates a patched image based on 'Standard Edition 2'
   -p: patch label to be used for the tag

* select one edition only: -e or -s

LICENSE UPL 1.0

Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

EOF
  exit 0
}

##############
#### MAIN ####
##############

if [ "$#" -eq 0 ]; then
  usage;
fi

# Parameters
ENTERPRISE=0
STANDARD=0
VERSION="12.2.0.1"
PATCHLABEL="Patch"
DOCKEROPS=""

while getopts "hesv:p:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "e")
      ENTERPRISE=1
      ;;
    "s")
      STANDARD=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "p")
      PATCHLABEL="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildPatchedDockerImage.sh"
      ;;
  esac
done

# Which Edition should be used?
if [ $((ENTERPRISE + STANDARD)) -gt 1 ]; then
  usage
elif [ $ENTERPRISE -eq 1 ]; then
  EDITION="ee"
elif [ $STANDARD -eq 1 ]; then
  EDITION="se2"
fi

# Oracle Database Image Name
IMAGE_NAME="oracle/database:$VERSION-$EDITION-$PATCHLABEL"

# Go into version folder
cd $VERSION

echo "=========================="
echo "DOCKER version:"
docker version
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
docker build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile.$EDITION . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle Database Docker Image for '$EDITION' version $VERSION patch $PATCHLABEL is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

else
  echo "Oracle Database Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

