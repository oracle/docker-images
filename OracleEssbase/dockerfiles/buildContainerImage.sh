#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: anil.arora@oracle.com
# Description: script to build a container image for Oracle Essbase
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

usage() {
cat << EOF

Usage: buildContainerImage.sh -v [version] [-s] [-c] [-q] [-o] [container build option]
Builds a Container Image for Oracle Essbase.

Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -c: enables container image layer cache during build
   -i: ignores the MD5 checksums
   -o: passes on container build option

LICENSE UPL 1.0

Copyright (c) 2021, Oracle and/or its affiliates.

EOF
exit 0
}

# Validate packages
checksumPackages() {
  if hash md5sum 2>/dev/null; then
    echo "Checking if required packages are present and valid..."   
    if ! md5sum -c "Checksum.md5"; then
      echo "MD5 for required packages to build this image did not match!"
      echo "Make sure to download missing files in folder ${VERSION}."
      exit 1;
    fi
  else
    echo "Ignored MD5 sum, 'md5sum' command not available.";
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
VERSION="21.1.0"
SKIPMD5=0
NOCACHE=true
declare -a BUILD_OPTS
MIN_DOCKER_VERSION="17.09"
MIN_PODMAN_VERSION="1.6.0"
DOCKERFILE="Dockerfile"

if [ "$#" -eq 0 ]; then
  usage;
  exit 1;
fi

while getopts "hciv:o:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "c")
      NOCACHE=false
      ;;
    "i")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "o")
      eval "BUILD_OPTS=(${OPTARG})"
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

# Check that we have a container runtime installed
checkContainerRuntime

# Image Name
IMAGE_NAME="oracle/essbase:$VERSION"

# Go into version folder
cd "${VERSION}" || {
  echo "Could not find version directory '${VERSION}'";
  exit 1;
}

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

echo "====================="

# Proxy settings
declare -a PROXY_SETTINGS
# shellcheck disable=SC2154
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS=("${PROXY_SETTINGS[@]}" "--build-arg" "http_proxy=${http_proxy}")
fi

# shellcheck disable=SC2154
if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS=("${PROXY_SETTINGS[@]}" "--build-arg" "https_proxy=${https_proxy}")
fi

# shellcheck disable=SC2154
if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS=("${PROXY_SETTINGS[@]}" "--build-arg" "ftp_proxy=${ftp_proxy}")
fi

# shellcheck disable=SC2154
if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS=("${PROXY_SETTINGS[@]}" "--build-arg" "no_proxy=${no_proxy}")
fi

if [ ${#PROXY_SETTINGS[@]} -gt 0 ]; then
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '${IMAGE_NAME}' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
"${CONTAINER_RUNTIME}" build --force-rm=${NOCACHE} --no-cache=${NOCACHE} \
       "${BUILD_OPTS[@]}" "${PROXY_SETTINGS[@]}" \
       -t "${IMAGE_NAME}" -f Dockerfile . || {
  echo ""
  echo "ERROR: Oracle Essbase container image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the build operation."
  exit 1
}

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle Essbase Container Image for version ${VERSION} is ready:

    --> ${IMAGE_NAME}

  Build completed in ${BUILD_ELAPSED} seconds.

EOF
else
  echo "Oracle Essbase Container Image was NOT successfully created. Check the output and correct any reported problems with the container build operation."
fi

