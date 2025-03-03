#!/bin/bash
#
# Copyright (c) 2022, Oracle and/or its affiliates
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

usage() {
  cat << EOF

Usage: buildPatchedContainerImage.sh -v [version] -t [image_name:tag] -p [patch version] [-o] [container build option]
It builds a patched RAC container image

Parameters:
   -v: version to build
   -o: passes on container build option
   -p: patch label to be used for the tag

LICENSE UPL 1.0

Copyright (c) 2014,2022 Oracle and/or its affiliates.

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
# shellcheck disable=SC2034
ENTERPRISE=0
# shellcheck disable=SC2034
STANDARD=0
# shellcheck disable=SC2034
LATEST="latest"
VERSION='19.3.0'
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
      echo "Unknown error while processing options inside buildPatchedContainerImage.sh"
      ;;
  esac
done

# Oracle Database Image Name
IMAGE_NAME="oracle/database-rac:$VERSION-$PATCHLABEL"

# Go into version folder
# shellcheck disable=SC2164
cd latest

# Proxy settings
PROXY_SETTINGS=""
# shellcheck disable=SC2154
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi
# shellcheck disable=SC2154
if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi
# shellcheck disable=SC2154
if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi
# shellcheck disable=SC2154
if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi
# shellcheck disable=SC2154
if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
# shellcheck disable=SC2046
docker build --no-cache=true $DOCKEROPS \
             --build-arg VERSION=$VERSION \
             $PROXY_SETTINGS -t $IMAGE_NAME -f Containerfile . || {
  echo "There was an error building the image."
  exit 1
}

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
# shellcheck disable=SC2320
if [ $? -eq 0 ]; then
cat << EOF
  Oracle Database container image for Real Application Clusters (RAC) version $VERSION is ready to be extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF

else
  echo "Oracle Database Real Application Clusters container image was NOT successfully created. Check the output and correct any reported problems that occurred during the build operation."
fi