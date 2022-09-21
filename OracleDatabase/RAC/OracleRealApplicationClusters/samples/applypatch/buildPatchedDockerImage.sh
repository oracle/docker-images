#!/bin/bash
#
# Since: November, 2018
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2014,2021 Oracle and/or its affiliates.
#

usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] -t [image_name:tag] -p [patch version] [-o] [container build option]
It builds a container image for RAC patched image

Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -o: passes on container build option
   -p: patch label to be used for the tag

LICENSE UPL 1.0

Copyright (c) 2014,2021 Oracle and/or its affiliates.

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
LATEST="latest"
VERSION='x'
PATCHLABEL="patch"
DOCKEROPS=""

while getopts "h:v:p:o:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "p")
      PATCHLABEL="$OPTARG"
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
IMAGE_NAME="oracle/database-rac:$VERSION-$PATCHLABEL"

# Go into version folder
cd latest

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
  Oracle Database Docker Image for Real Application Clusters (RAC) version $VERSION is ready to be extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF

else
  echo "Oracle Database Real Application Clusters Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
