#!/bin/bash
# Copyright (c)  2020,2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: script to build a Docker image for Oracle WebCenter Portal
#
usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-s] [-c]
Builds a Docker Image for Oracle WebCenter Portal.

Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -c: enables Docker image layer cache during build
   -s: skips the MD5 check of packages


 Copyright (c) 2020, 2021, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

EOF
exit 0
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
VERSION="12.2.1.4"
SKIPMD5=0
NOCACHE=true
IMAGE_VERSION=$VERSION

while getopts "hscv:i:" optname; do
case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "c")
      NOCACHE=false
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "i")
      IMAGE_VERSION="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# WebCenter Portal Image Name
echo "Version: " $VERSION
IMAGE_NAME="oracle/wcportal:$IMAGE_VERSION"
echo "Image name: " $IMAGE_NAME

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  MD5CMD="md5sum -c Checksum"
  if ! [ -x "$(command -v md5sum)" ]; then
    MD5CMD="docker run -it --rm -v$(pwd):/md5dir oracle/serverjre:8 sh -c cd /md5dir; ${MD5CMD}"
  fi
  $MD5CMD
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION. See *.download files for more information"
    exit $?
  fi
}
# Go into version folder
cd $VERSION

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

echo "====================="

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
  Oracle WebCenter Portal Docker Image for version $VERSION is ready to be extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "Oracle WebCenter Portal Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

