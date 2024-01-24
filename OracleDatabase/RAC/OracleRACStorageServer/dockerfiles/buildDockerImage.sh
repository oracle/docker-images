#!/bin/bash
# LICENSE UPL 1.0
# 
# Since: January, 2018
# Author: Paramdeep saini <paramdeep.saini@oracle.com>
# Description: Build script for building Oracle RAC Storage Server Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2024 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
  cat << EOF

Usage: buildDockerImage.sh -v [version] [-o] [Docker build option]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose one of: $(for i in */; do echo -n "${i%/}  "; done)
   -o: passes on Docker build option

LICENSE UPL 1.0

Copyright (c) 2014-2024 Oracle and/or its affiliates. All rights reserved.

EOF
  exit 0
}

##############
#### MAIN ####
##############

# Parameters
VERSION="latest"
DOCKEROPS=("${DOCKEROPS[@]}")
PROXY_SETTINGS=("${PROXY_SETTINGS[@]}")

while getopts "hiv:o:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "o")
      DOCKEROPS=("$OPTARG")
      ;;
    "?")
      usage
      # shellcheck disable=SC2317
      exit 1
      ;;
    *)
      # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done


# Oracle Database Image Name
IMAGE_NAME="oracle/rac-storage-server:$VERSION"

# Go into version folder
cd "$VERSION" || { echo "Error: Unable to change to directory $VERSION"; exit 1; }


echo "=========================="
echo "DOCKER info:"
docker info
echo "=========================="

# Proxy settings
if [ -n "${http_proxy-}" ]; then
  PROXY_SETTINGS+=("--build-arg http_proxy=${http_proxy}")
fi

if [ -n "${https_proxy-}" ]; then
  PROXY_SETTINGS+=("--build-arg https_proxy=${https_proxy}")
fi

if [ -n "${ftp_proxy-}" ]; then
  PROXY_SETTINGS+=("--build-arg ftp_proxy=${ftp_proxy}")
fi

if [ -n "${no_proxy-}" ]; then
  PROXY_SETTINGS+=("--build-arg no_proxy=${no_proxy}")
fi
# shellcheck disable=SC2128
if [ -n "$PROXY_SETTINGS" ]; then
  echo "Proxy settings were found and will be used during the build."
fi


# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
if docker build --force-rm=true --no-cache=true "${DOCKEROPS[@]}" "${PROXY_SETTINGS[@]}" -t "$IMAGE_NAME" -f Dockerfile .; then
  BUILD_END=$(date '+%s')
  BUILD_ELAPSED=$((BUILD_END - BUILD_START))

  echo ""
  cat << EOF
  Oracle RAC Storage Server Docker Image version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF
else
  echo "Oracle RAC Storage Server Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
  exit 1
fi
