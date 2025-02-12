#!/bin/bash
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
############################

usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] [-o] [Docker build option]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose "latest" version for podman host machines
       Choose "ol7" version for docker host machines
   -o: passes on Docker build option

#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

EOF
  exit 0
}

##############
#### MAIN ####
##############

# Parameters
VERSION="latest"
export SKIPMD5=0
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
      echo "Unknown error while processing options inside buildContainerImage.sh"
      ;;
  esac
done

# Oracle Database Image Name
IMAGE_NAME="oracle/rac-storage-server:$VERSION"
if command -v docker &>/dev/null; then
    CONTAINER_BUILD_TOOL="docker"
elif command -v podman &>/dev/null; then
    CONTAINER_BUILD_TOOL="podman"
else
    echo "Neither Docker nor Podman is installed. Please install either Docker or Podman to proceed."
    exit 1
fi
# Go into version folder
cd "$VERSION" || exit

echo "=========================="
echo "DOCKER info:"
docker info
echo "=========================="

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
# shellcheck disable=SC2086
$CONTAINER_BUILD_TOOL build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Containerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
# shellcheck disable=SC2154,SC2003
BUILD_ELAPSED=$((BUILD_END - BUILD_START))

echo ""
# shellcheck disable=SC2181,SC2320
if [ $? -eq 0 ]; then
cat << EOF
  Oracle RAC Storage Server Container Image version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

else
  echo "Oracle RAC Storage Server Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi