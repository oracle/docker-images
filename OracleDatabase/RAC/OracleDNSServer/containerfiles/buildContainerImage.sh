#!/bin/bash
#
# Since: November, 2018
# Author: paramdeep.saini@oracle.com
# Description: Build script for building DNS server container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2018-2025 Oracle and/or its affiliates.
#
# shellcheck disable=SC2154
usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-e | -s | -x] [-i] [-o] [container build option]
It builds a container image for a DNS server

Parameters:
   -v: version to build
       Choose one of: $(for i in */; do echo -n "${i%%/}  "; done)
   -o: passes on container build option

LICENSE UPL 1.0

Copyright (c) 2014,2021 Oracle and/or its affiliates.

EOF
  exit 0
}

# Validate packages
checksumPackages() {
  if hash md5sum 2>/dev/null; then
    echo "Checking if required packages are present and valid..."
    md5sum -c Checksum
    md5_exit_code=$?

    if [ "$md5_exit_code" -ne 0 ]; then
        echo "MD5 for required packages to build this image did not match!"
        echo "Make sure to download missing files in folder $VERSION."
        exit "$md5_exit_code"
    fi
  else
    echo "Ignored MD5 sum, 'md5sum' command not available."
  fi
}

##############
#### MAIN ####
##############

if [ "$#" -eq 0 ]; then
  usage;
fi

# Parameters
VERSION="latest"
DOCKEROPS=("${DOCKEROPS[@]}")
PROXY_SETTINGS=("${PROXY_SETTINGS[@]}")

while getopts "h:v:o:" optname; do
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
IMAGE_NAME="oracle/rac-dnsserver:$VERSION"

# Go into version folder
cd "$VERSION" || exit


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
if docker build --force-rm=true --no-cache=true "${DOCKEROPS[@]}" "${PROXY_SETTINGS[@]}"  -t "$IMAGE_NAME" -f Containerfile .; then
  BUILD_END=$(date '+%s')
  BUILD_ELAPSED=$((BUILD_END - BUILD_START))
  
  cat << EOF
  Oracle Database Docker Image for Real Application Clusters (RAC) version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF
else
  echo "There was an error building the image."
  exit 1
fi