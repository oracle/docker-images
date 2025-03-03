#!/bin/bash -e
# 
# Since: April, 2016
# Author: gerald.venzl@oracle.com
# Description: Build script for building Oracle Database container images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014,2024 Oracle and/or its affiliates.
# 

usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-e | -s | -x | -f] [-i] [-p] [-b] [-o] [container build option]
Builds a container image for Oracle Database.

Parameters:
   -v: version to build
       Choose one of: $(for i in */; do echo -n "${i%%/}  "; done)
   -t: image_name:tag for the generated docker image
   -e: creates image based on 'Enterprise Edition'
   -s: creates image based on 'Standard Edition 2'
   -x: creates image based on 'Express Edition'
   -f: creates images based on Database 'Free' 
   -i: ignores the MD5 checksums
   -p: creates and extends image using the patching extension
   -b: build base stage only (Used by extensions)
   -o: passes on container build option

* select one edition only: -e, -s, -x, or -f

LICENSE UPL 1.0

Copyright (c) 2014,2024 Oracle and/or its affiliates.

EOF

}

# Validate packages
checksumPackages() {
  if hash md5sum 2>/dev/null; then
    echo "Checking if required packages are present and valid..."   
    if ! md5sum -c "Checksum.${EDITION}${PLATFORM}"; then
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
  DOCKER_VERSION=$("${CONTAINER_RUNTIME}" version --format '{{.Server.Version }}'|| exit 0)
  # Remove dot in Docker version
  DOCKER_VERSION=${DOCKER_VERSION//./}

  if [ "${DOCKER_VERSION}" -lt "${MIN_DOCKER_VERSION//./}" ]; then
    echo "Docker version is below the minimum required version ${MIN_DOCKER_VERSION}"
    echo "Please upgrade your Docker installation to proceed."
    exit 1;
  fi;
}

##############
#### MAIN ####
##############

# Go into dockerfiles directory
cd "$(dirname "$0")"

# Parameters
ENTERPRISE=0
STANDARD=0
EXPRESS=0
FREE=0
PATCHING=0
BASE_ONLY=0
# Obtaining the latest version to build
VERSION="$(find -- *.*.* -type d | tail -n 1)"
SKIPMD5=0
declare -a BUILD_OPTS
MIN_DOCKER_VERSION="17.09"
MIN_PODMAN_VERSION="1.6.0"
DOCKERFILE="Dockerfile"
IMAGE_NAME=""

if [ "$#" -eq 0 ]; then
  usage;
  exit 1;
fi

while getopts "hesxfiv:t:o:pb" optname; do
  case "${optname}" in
    "h")
      usage
      exit 0;
      ;;
    "i")
      SKIPMD5=1
      ;;
    "e")
      ENTERPRISE=1
      ;;
    "s")
      STANDARD=1
      ;;
    "x")
      EXPRESS=1
      ;;
    "f")
      FREE=1
      ;;
    "p")
      PATCHING=1
      ;;
    "b")
      BASE_ONLY=1
      ;;
    "v")
      VERSION="${OPTARG}"
      ;;
    "t")
      IMAGE_NAME="${OPTARG}"
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

# Only 19c EE is supported on ARM64 platform
if [ "$(arch)" == "aarch64" ] || [ "$(arch)" == "arm64" ]; then
  BUILD_OPTS=("--build-arg" "BASE_IMAGE=oraclelinux:8" "${BUILD_OPTS[@]}")
  PLATFORM=".arm64"
  if { [ "${VERSION}" == "19.3.0" ] && [ "${ENTERPRISE}" -eq 1 ]; }; then
    BUILD_OPTS=("--build-arg" "INSTALL_FILE_1=LINUX.ARM64_1919000_db_home.zip" "${BUILD_OPTS[@]}")
  elif { [ "${VERSION}" == "23.6.0" ] && [ "${FREE}" -eq 1 ]; }; then
    BUILD_OPTS=("--build-arg" "INSTALL_FILE_1=https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23ai-1.0-1.el8.aarch64.rpm" "${BUILD_OPTS[@]}")
  else
    echo "Currently only 19c enterprise edition is supported on ARM64 platform.";
    exit 1;
  fi;
fi;

# Which Edition should be used?
if [ $((ENTERPRISE + STANDARD + EXPRESS + FREE)) -gt 1 ]; then
  usage
elif [ ${ENTERPRISE} -eq 1 ]; then
  EDITION="ee"
elif [ ${STANDARD} -eq 1 ]; then
  EDITION="se2"
elif [ ${EXPRESS} -eq 1 ]; then
  if [ "${VERSION}" == "18.4.0" ]; then
    EDITION="xe"
    SKIPMD5=1
  elif [ "${VERSION}" == "21.3.0" ]; then
    EDITION="xe"
    SKIPMD5=1
  elif [ "${VERSION}" == "11.2.0.2" ]; then
    EDITION="xe"
    BUILD_OPTS=("--shm-size=1G" "${BUILD_OPTS[@]}")
  else
    echo "Version ${VERSION} does not have Express Edition available.";
    exit 1;
  fi;
elif [ ${FREE} -eq 1 ]; then 
  if [ "$(cut -f1 -d.  <<< "$VERSION" )" -lt 23 ]; then 
    echo "Version ${VERSION} does not have Free Edition available.";
    exit 1;
  else 
    EDITION="free"
    SKIPMD5=1
  fi;
fi;

# Go into version folder
cd "${VERSION}" || {
  echo "Could not find version directory '${VERSION}'";
  exit 1;
}

# Which Dockerfile should be used?
if [ "${VERSION}" == "12.1.0.2" ] || [ "${VERSION}" == "11.2.0.2" ] || [ "${VERSION}" == "18.4.0" ] || [ "${VERSION}" == "23.6.0" ] || { [ "${VERSION}" == "21.3.0" ] && [ "${EDITION}" == "xe" ]; }; then
  DOCKERFILE=$( if [[ -f "Containerfile.${EDITION}" ]]; then echo "Containerfile.${EDITION}"; else echo "${DOCKERFILE}.${EDITION}";fi )
fi;

echo "$DOCKERFILE"

# Oracle Database image Name
# If provided using -t build option then use it; Otherwise, create with version and edition
if [ -z "${IMAGE_NAME}" ]; then
  IMAGE_NAME="oracle/database:${VERSION}-${EDITION}"
  if [ ${BASE_ONLY} -eq 1 ]; then
    IMAGE_NAME="oracle/database:${VERSION}-base"
  fi
fi;

if [ ${BASE_ONLY} -eq 0 ] && [ ! "${SKIPMD5}" -eq 1 ]; then
  checksumPackages
else
  echo "Ignored MD5 checksum."
fi
echo "=========================="
echo "Container runtime info:"
"${CONTAINER_RUNTIME}" info
echo "=========================="

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

if [ ${PATCHING} -eq 1 ]; then
  # Setting SLIMMING to false to support patching
  BUILD_OPTS=("${BUILD_OPTS[@]}" "--build-arg" "SLIMMING=false" )
fi

if [ ! -e "${DOCKERFILE}" ]; then
  echo "ERROR: ${DOCKERFILE} doesn't exist"
  exit 1
fi

# ############################# #
# BUILDING THE BASE STAGE IMAGE #
# ############################# #

if [ ${BASE_ONLY} -eq 1 ]; then
  echo "Building base stage image '${IMAGE_NAME}' ..."
  # BUILD THE BASE STAGE IMAGE (replace all environment variables)
  "${CONTAINER_RUNTIME}" build --force-rm=true \
        "${BUILD_OPTS[@]}" "${PROXY_SETTINGS[@]}" --target base \
        -t "${IMAGE_NAME}" -f "${DOCKERFILE}" . || {
    echo ""
    echo "ERROR: Base stage image was NOT successfully created."
    exit 1
  }
  # Remove dangling images (intermitten images with tag <none>)
  yes | "${CONTAINER_RUNTIME}" image prune > /dev/null || true
  exit
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '${IMAGE_NAME}' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
"${CONTAINER_RUNTIME}" build --force-rm=true --no-cache=true \
      "${BUILD_OPTS[@]}" "${PROXY_SETTINGS[@]}" --build-arg DB_EDITION="${EDITION}" \
      -t "${IMAGE_NAME}" -f "${DOCKERFILE}" . || {
  echo ""
  echo "ERROR: Oracle Database container image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the build operation."
  exit 1
}

# Remove dangling images (intermitten images with tag <none>)
yes | "${CONTAINER_RUNTIME}" image prune > /dev/null || true

BUILD_END=$(date '+%s')
BUILD_ELAPSED=$(( BUILD_END - BUILD_START ))

echo ""
echo ""

cat << EOF
  Oracle Database container image for '${EDITION}' version ${VERSION} is ready to be extended: 
    
    --> ${IMAGE_NAME}

  Build completed in ${BUILD_ELAPSED} seconds.
  
EOF

# EXTEND THE BUILT IMAGE BY APPLYING PATCHING EXTENSION
if [ ${PATCHING} -eq 1 ]; then
  ../../extensions/buildExtensions.sh -b "${IMAGE_NAME}" -t "${IMAGE_NAME}"-ext -v "${VERSION}" -x 'patching'
fi