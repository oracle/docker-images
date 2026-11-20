#!/bin/bash -e
# shellcheck disable=SC2086,SC2154
# 
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Build script for building Container Image Extensions
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2023-2026 Oracle and/or its affiliates. All rights reserved.
# 

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")

usage() {
  cat << EOF

Usage: $SCRIPT_NAME -a -x [extensions] -b [base image] -t [image name] -v [version] [-o] [container build option]
Builds one of more Container Image Extensions.
  
Parameters:
   -a: Build all extensions
   -x: Space separated extensions to build. Defaults to all
       Choose from : $(for i in $(cd "$SCRIPT_DIR" && ls -d -- */); do echo -n "${i%%/}  "; done)
   -b: Base image to use
   -v: Base version to extend (example 21.3.0)
   -t: name:tag for the extended image
   -o: passes on Container build option

LICENSE UPL 1.0

Copyright (c) 2023-2026 Oracle and/or its affiliates. All rights reserved.

EOF

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
    BUILD_FORMAT_OPTIONS=(--format=docker)
  fi
}

# Remove only base-stage tags created during this build, including on failure.
cleanupBaseImages() {
  local base_image
  for base_image in "${BASE_IMAGES_TO_CLEAN[@]}"; do
    if "${CONTAINER_RUNTIME}" image inspect "$base_image" >/dev/null 2>&1; then
      "${CONTAINER_RUNTIME}" rmi -f "$base_image" ||
        echo "WARNING: Could not remove temporary base image '$base_image'." >&2
    fi
  done
  BASE_IMAGES_TO_CLEAN=()
}

##############
#### MAIN ####
##############

# Parameters
DOCKEROPS=""
DOCKERFILE="Dockerfile"
BASE_IMAGE="oracle/database:latest"
IMAGE_NAME="oracle/database:ext"
VERSION=""
declare -a BUILD_FORMAT_OPTIONS
BASE_IMAGES_TO_CLEAN=()

if [ "$#" -eq 0 ]; then
  usage;
  exit 1;
fi

while getopts "ax:b:t:v:o:h" optname; do
  case "$optname" in
    a)
      EXTENSIONS=$(for i in $(cd "$SCRIPT_DIR" && ls -d -- */); do echo -n "${i%%/}  "; done)
      ;;
    x)
      EXTENSIONS="$OPTARG"
      ;;
    b)
      BASE_IMAGE="$OPTARG"
      ;;
    t)
      IMAGE_NAME="$OPTARG"
      ;;
    v)
      VERSION="$OPTARG"
      ;;
    o)
      DOCKEROPS="$OPTARG"
      ;;
    h|?)
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
if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #

BUILD_START=$(date '+%s')

cd "$SCRIPT_DIR"

BUILD_BASE_STAGE=false
FREE_PREBUILT=false
if [[ " $EXTENSIONS " == *" prebuiltdb "* ]]; then
  if ! "${CONTAINER_RUNTIME}" image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
    "${CONTAINER_RUNTIME}" pull "$BASE_IMAGE"
  fi
  BASE_IMAGE_RELEASE=$("${CONTAINER_RUNTIME}" image inspect --format '{{ index .Config.Labels "release" }}' "$BASE_IMAGE")
  if [ "$BASE_IMAGE_RELEASE" = "Free" ]; then
    FREE_PREBUILT=true
    for extension in $EXTENSIONS; do
      if [ "$extension" != "prebuiltdb" ]; then
        echo "ERROR: prebuiltdb must be the first extension for Free images because its final stage rebuilds from a clean base."
        echo "Example: -x 'prebuiltdb truecache sharding'"
        exit 1
      fi
      break
    done
  fi
fi
if [[ "$EXTENSIONS" == *"patching"* ]]; then
  if [ "$( (ls patching/patches/one_offs && ls patching/patches/release_update) | wc -l)" -gt 0 ]; then
    BUILD_BASE_STAGE=true
  fi
fi
if [ "$FREE_PREBUILT" = true ]; then
  BUILD_BASE_STAGE=true
fi

if [ "$BUILD_BASE_STAGE" = true ]; then
  if [ -z "$VERSION" ]; then
    if ! "${CONTAINER_RUNTIME}" image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
      "${CONTAINER_RUNTIME}" pull "$BASE_IMAGE"
    fi
    VERSION=$("${CONTAINER_RUNTIME}" image inspect --format '{{ index .Config.Labels "version" }}' "$BASE_IMAGE")
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "ERROR: -v is required when the base image has no valid version label"
      exit 1
    fi
  fi

  # BUILD THE LINUX BASE FOR REUSE
  BASE_BUILD_EDITION_ARGS=()
  case "${BASE_IMAGE##*:}" in
    *-free)
      BASE_BUILD_EDITION_ARGS=("-f")
      ;;
    *-se2)
      BASE_BUILD_EDITION_ARGS=("-s")
      ;;
    *-xe)
      BASE_BUILD_EDITION_ARGS=("-x")
      ;;
  esac
  if [ "$FREE_PREBUILT" = true ]; then
    BASE_BUILD_EDITION_ARGS=("-f")
  fi
  trap cleanupBaseImages EXIT
  ../dockerfiles/buildContainerImage.sh -b -v "${VERSION}" "${BASE_BUILD_EDITION_ARGS[@]}" -t "$BASE_IMAGE"-base
  BASE_IMAGES_TO_CLEAN+=("${BASE_IMAGE}-base")
fi

for x in $EXTENSIONS; do
  echo "Building extension $x..."
  # Go into version folder
  cd "$x" || {
    echo "Could not find extension directory '$x'";
    exit 1;
  }

  BUILD_CONTEXT_OPTIONS=()
  EXTENSION_DOCKERFILE="$DOCKERFILE"
  if [ "$x" = "prebuiltdb" ] && [ "$FREE_PREBUILT" = true ]; then
    EXTENSION_DOCKERFILE="Dockerfile.free"
  fi
  if [ "$x" = "sharding" ]; then
    BUILD_CONTEXT_OPTIONS=(--build-context "gdd-scripts=../../../GDD/containerfiles/scripts")
  fi

  # shellcheck disable=SC2086
  "${CONTAINER_RUNTIME}" build --force-rm=true "${BUILD_FORMAT_OPTIONS[@]}" --build-arg BASE_IMAGE="$BASE_IMAGE" \
       "${BUILD_CONTEXT_OPTIONS[@]}" $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f "$EXTENSION_DOCKERFILE" . || {
  echo ""
  echo "ERROR: Oracle Database Container Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the container build operation."
  exit 1
  }
  if [ "$BASE_IMAGE" != "$IMAGE_NAME" ] && "${CONTAINER_RUNTIME}" image inspect "${BASE_IMAGE}"-base >/dev/null 2>&1; then
      "${CONTAINER_RUNTIME}" tag "$BASE_IMAGE"-base "$IMAGE_NAME"-base
      if [ "$BUILD_BASE_STAGE" = true ]; then
        BASE_IMAGES_TO_CLEAN+=("${IMAGE_NAME}-base")
      fi
  fi
  BASE_IMAGE="$IMAGE_NAME"
  cd ..
done

cleanupBaseImages

# Remove dangling images (intermitten images with tag <none>)
"${CONTAINER_RUNTIME}" image prune -f > /dev/null

BUILD_END=$(date '+%s')
BUILD_ELAPSED=$(( BUILD_END - BUILD_START ))

echo ""
echo ""

cat<<EOF
  Oracle Database Container Image extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
