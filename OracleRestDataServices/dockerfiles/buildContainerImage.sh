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

Usage: buildContainerImage.sh [-i] [-o] [Docker build option]
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
  # Check if Checksum file exists
  if [ -f "Checksum.$VERSION" ]; then
    echo "Checking if required packages are present and valid..."
    md5sum -c "Checksum.$VERSION"
    ret=$?
    if [ "$ret" -ne 0 ]; then
      echo "MD5 for required packages to build this image did not match!"
      echo "Make sure to download missing files."
      exit "$ret"
    fi
  fi
}

# Check container runtime
checkContainerRuntime() {
  CONTAINER_RUNTIME=$(which docker 2>/dev/null) ||
    CONTAINER_RUNTIME=$(which podman 2>/dev/null) ||
    {
      echo "No docker or podman executable found in your PATH"
      exit 1
    }

  if "${CONTAINER_RUNTIME}" info | grep -i -q buildahversion; then
    checkPodmanVersion
  else
    checkDockerVersion
  fi
}

# Check Podman version
checkPodmanVersion() {
  # Get Podman version
  echo "Checking Podman version."
  PODMAN_VERSION=$("${CONTAINER_RUNTIME}" info --format '{{.host.BuildahVersion}}' 2>/dev/null ||
                   "${CONTAINER_RUNTIME}" info --format '{{.Host.BuildahVersion}}')
  # Remove dot in Podman version
  PODMAN_VERSION=${PODMAN_VERSION//./}

  if [ -z "${PODMAN_VERSION}" ]; then
    exit 1;
  elif [ "${PODMAN_VERSION}" -lt "${MIN_PODMAN_VERSION//./}" ]; then
    echo "Podman version is below the minimum required version ${MIN_PODMAN_VERSION}"
    echo "Please upgrade your Podman installation to proceed."
    exit 1;
  fi
}

# Check Docker version
checkDockerVersion() {
  # Get Docker Server version
  echo "Checking Docker version."
  DOCKER_VERSION=$("${CONTAINER_RUNTIME}" version --format '{{.Server.Version | printf "%.5s" }}'|| exit 0)
  # Remove dot in Docker version
  DOCKER_VERSION=${DOCKER_VERSION//./}

  if [ "${DOCKER_VERSION}" -lt "${MIN_DOCKER_VERSION//./}" ]; then
    echo "Docker version is below the minimum required version ${MIN_DOCKER_VERSION}"
    echo "Please upgrade your Docker installation to proceed."
    exit 1;
  fi;
}

# Parameters
VERSION=""
SKIPMD5=0
MIN_DOCKER_VERSION="17.09"
MIN_PODMAN_VERSION="1.6.0"
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

# Check that we have a container runtime installed
checkContainerRuntime

# Determine latest version
# Do this after the options so that users can still do a "-h"
ORDS_ZIP_COUNT="$(ls -al ords*zip 2>/dev/null | wc -l)"
if [ "${ORDS_ZIP_COUNT}" -eq 0 ]; then
  VERSION="latest"
elif [ "${ORDS_ZIP_COUNT}" -gt 1 ]; then
  echo "ERROR: Found multiple versions of ORDS zip files.";
  echo "ERROR: Please only put one ORDS zip file into this directory!";
  exit 1;
else
  # #644: using awk as below does not work in macOS bash as it's really gawk (3 params) - see ticket for more info
  # VERSION=$(ls ords*zip 2>/dev/null | awk 'match ($0, /(ords\.)(.{1,2}\..{1,2}\..{1,2})\.(.+.zip)/, result) { print result[2] }')
  ORDS_FILENAME=$(ls ords*zip 2>/dev/null)
  ORDS_FILENAME_REGEXP="(ords(\.|-))(.{1,2}\..{1,2}\..{1,2})(\..*)(zip)"

  if [[ $ORDS_FILENAME =~ $ORDS_FILENAME_REGEXP ]]; then
    VERSION="${BASH_REMATCH[3]}"
  else
    VERSION=""
  fi;

fi;

if [ -z "$VERSION" ]; then
  echo "ERROR: No install file is in this directory!"
  echo "ERROR: Please copy the install file into this directory or refer to the ReadMe!"
  exit 1;
fi;


# Oracle Database Image Name
IMAGE_NAME="oracle/restdataservices:$VERSION"

if [ ! "$SKIPMD5" -eq 1 ] && [ "$VERSION" != "latest" ]; then
  checksumPackages
else
  echo "Ignored MD5 checksum."
fi

echo "=========================="
echo "Container Runtime info:"
"${CONTAINER_RUNTIME}" info
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
"${CONTAINER_RUNTIME}" build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS \
             -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=$((BUILD_END - BUILD_START))

echo ""

cat << EOF
  Oracle Rest Data Services version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF
