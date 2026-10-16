#!/bin/bash
# shellcheck disable=SC2086,SC2154,SC2181
#
# Since: November, 2018
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2014,2024 Oracle and/or its affiliates.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/baseImageMetadata.sh"

checkContainerRuntime() {
  CONTAINER_RUNTIME=$(command -v podman 2>/dev/null) ||
    CONTAINER_RUNTIME=$(command -v docker 2>/dev/null) ||
    {
      echo "No docker or podman executable found in your PATH"
      exit 1
    }
}

usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-b] [-i] [-o] [container build option]
It builds a container image for a DNS server

Parameters:
   -v: version to build
   -i: ignores the MD5 checksums
   -t: user defined image name and tag (e.g., image_name:ta
   -o: passes on container build option (e.g., --build-arg SLIMMIMG=true for slim)
   -b: build base stage only (Used by extensions)

LICENSE UPL 1.0

Copyright (c) 2014,2024 Oracle and/or its affiliates.

EOF
  exit 0
}

# Validate packages (Checksum may contain MD5 or SHA256 digests)
checksumPackages() {
  local checksum_file="${VERSION}/Checksum"
  local hash_algo="md5"
  local check_cmd="md5sum"
  local sample_hash

  if [ ! -f "${checksum_file}" ]; then
    echo "Checksum file ${checksum_file} not found."
    exit 1
  fi

  sample_hash="$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "${checksum_file}")"
  if [[ "${sample_hash}" =~ ^[[:xdigit:]]{64}$ ]]; then
    hash_algo="sha256"
    check_cmd="sha256sum"
  fi

  if command -v "${check_cmd}" >/dev/null 2>&1; then
    echo "Checking if required packages are present and valid (${hash_algo})..."
    if ! (cd "${VERSION}" && "${check_cmd}" -c Checksum); then
      echo "${hash_algo} validation failed for required packages."
      echo "Make sure the required files are present in ${VERSION} and match its Checksum file."
      exit 1
    fi
  else
    echo "Ignored checksum, '${check_cmd}' command not available."
  fi
}

##############
#### MAIN ####
##############

if [ "$#" -eq 0 ]; then
  usage;
fi

# Parameters
VERSION="19.3.0"
SKIPMD5=0
BASE_ONLY=0
DOCKEROPS=""
IMAGE_NAME=""
SLIM="false"
DOCKEROPS=" --build-arg SLIMMING=false"
while getopts "hibv:o:t:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "i")
      SKIPMD5=1
      ;;
    "b")
      BASE_ONLY=1
      SKIPMD5=1
      ;;      
    "v")
      VERSION="$OPTARG"
      ;;
    "o")
      DOCKEROPS="$OPTARG"
      if [[ "$DOCKEROPS" != *"--build-arg SLIMMING="* ]]; then
         DOCKEROPS+=" --build-arg SLIMMING=false"
         SLIM="false"
      fi
      if [[ "$OPTARG" == *"--build-arg SLIMMING=true"* ]]; then
        SLIM="true"
      fi
     ;;
    "t")
      IMAGE_NAME="$OPTARG"
     ;;

    "?")
      usage >&2
      exit 1;
      ;;      
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildContainerImage.sh"
      ;;
  esac
done

# Oracle GSM/GDD Image Name
if [ "${BASE_ONLY}" -eq 1 ]; then
  if [ "${IMAGE_NAME}"x = "x" ]; then
    IMAGE_NAME="localhost/oracle/gsm:${VERSION}-base"
    if [ "$VERSION" = "23.26.0" ]; then
      IMAGE_NAME="localhost/oracle/gsm:23.26ai-base"
    fi
  else
    echo "Image name is passed as a variable"
  fi

  DOCKEROPS="${DOCKEROPS//--build-arg SLIMMING=true/}"
  DOCKEROPS="${DOCKEROPS//--build-arg SLIMMING=false/}"
  DOCKEROPS+=" --build-arg SLIMMING=true"

elif [ "${IMAGE_NAME}"x = "x" ] && [ "${SLIM}" == "true" ]; then
  IMAGE_NAME="oracle/gsm:${VERSION}-slim"
elif [ "${IMAGE_NAME}"x = "x" ] && [ "${SLIM}" == "false" ]; then
  IMAGE_NAME="oracle/gsm:${VERSION}"
else
  echo "Image name is passed as a variable"
fi

if [ "$VERSION" = "23.26.0" ]; then
  case "$IMAGE_NAME" in
    oracle/gsm:23.26.0)
      IMAGE_NAME="oracle/gsm:23.26ai"
      ;;
    oracle/gsm:23.26.0-slim)
      IMAGE_NAME="oracle/gsm:23.26ai-slim"
      ;;
  esac
fi

echo "Container Image set to : ${IMAGE_NAME}"

if [ "${VERSION%%.*}" -ge 19 ]; then
  BUILD_FILE="Containerfile"
else
  BUILD_FILE="Dockerfile"
fi

# Resolve the digest before building the selected GSM version.
checkContainerRuntime
case "${VERSION}" in
  19.3.0*) BASE_IMAGE_DEFAULT="oraclelinux:7" ;;
  21.*)    BASE_IMAGE_DEFAULT="oraclelinux:8" ;;
  *)       BASE_IMAGE_DEFAULT="oraclelinux:9" ;;
esac
resolve_base_image_metadata "${VERSION}" "${BASE_IMAGE_DEFAULT}" "${DOCKEROPS}"
DOCKEROPS="${DOCKEROPS} ${BASE_IMAGE_BUILD_ARGS}"

# Go into version folder
# cd "$VERSION" || exit

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Ignored MD5 checksum."
fi
echo "=========================="
echo "${CONTAINER_RUNTIME} info:"
"${CONTAINER_RUNTIME}" info
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

# ############################# #
# BUILDING THE BASE STAGE IMAGE #
# ############################# #

if [ ${BASE_ONLY} -eq 1 ]; then
  echo "Building base stage image '${IMAGE_NAME}' ..."
  # BUILD THE BASE STAGE IMAGE (replace all environment variables)
  "${CONTAINER_RUNTIME}" build --force-rm=true \
        --no-cache=true ${DOCKEROPS} ${PROXY_SETTINGS} --build-arg VERSION="${VERSION}" --target final \
        -t "${IMAGE_NAME}" -f "${VERSION}"/Containerfile . || {
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
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
# shellcheck disable=SC2086
"${CONTAINER_RUNTIME}" build --force-rm=true --no-cache=true ${DOCKEROPS} ${PROXY_SETTINGS} --build-arg VERSION="${VERSION}" --target final -t ${IMAGE_NAME} -f "${VERSION}/${BUILD_FILE}" . || {
  echo "There was an error building the image."
  exit 1
}

if [ $? -eq 0 ]; then

  BUILD_END=$(date '+%s')
  # shellcheck disable=SC2154,SC2003
  BUILD_ELAPSED=$((BUILD_END - BUILD_START))

  echo ""
  # shellcheck disable=SC2181,SC2320
cat << EOF
  Oracle GSM Container Image for version $VERSION is ready to be extended:

    --> $IMAGE_NAME
  
  Build completed in $BUILD_ELAPSED seconds.

EOF

else
  echo "Oracle GSM Container Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
