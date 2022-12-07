#!/bin/bash
# 
# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: steve.phillips@oracle.com
# Description: script to build a Docker image for Oracle Analytics Server
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

usage() {
cat << EOF

Usage: buildContainerImage.sh -v [version] [-s] [-c] [-q]
Builds a container image for Oracle Analytics.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in */; do echo -n "${i%%/}  "; done)
   -c: enables image layer cache during build
   -s: skips the MD5 check of packages
   -q: squash resulting image

LICENSE UPL 1.0

Copyright (c) 2022 Oracle and/or its affiliates.

EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum.md5
  exit_code="$?"
  if [ "$exit_code" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION. See *.download files for more information"
    exit "$exit_code"
  fi
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
VERSION="6.4"
SKIPMD5=0
NOCACHE=true
SQUASH=""
while getopts "qhcsv:" optname; do
  case "$optname" in
    "q")
      SQUASH="--squash"
      ;;
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "c")
      NOCACHE=false
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildContainerImage.sh"
      ;;
  esac
done

# Image Name
IMAGE_NAME="oracle/analyticsserver:$VERSION"

# Go into version folder
cd "$VERSION" || exit 1

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

echo "====================="

# Proxy settings
PROXY_SETTINGS=""
http_proxy="${http_proxy:=}"
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

https_proxy="${https_proxy:=}"
if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

ftp_proxy="${ftp_proxy:=}"
if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi

no_proxy="${no_proxy:=}"
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
docker_build_command="docker build --force-rm=$NOCACHE --no-cache=$NOCACHE $SQUASH $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile ."
${docker_build_command} || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=$(( BUILD_END - BUILD_START ))

echo ""

cat << EOF
  Oracle Analytics container image for version $VERSION is ready: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF

