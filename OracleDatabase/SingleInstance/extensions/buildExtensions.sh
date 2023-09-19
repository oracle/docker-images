#!/bin/bash -e
# 
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Build script for building Container Image Extensions
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2023 Oracle and/or its affiliates. All rights reserved.
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

Copyright (c) 2023 Oracle and/or its affiliates. All rights reserved.

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
}

##############
#### MAIN ####
##############

# Parameters
DOCKEROPS=""
DOCKERFILE="Dockerfile"
BASE_IMAGE="oracle/database:21.3.0-ee"
IMAGE_NAME="oracle/database:ext"
VERSION="21.3.0"

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

if [ "$EXTENSIONS" != "prebuiltdb" ]; then 
  # BUILD THE LINUX BASE FOR REUSE
  ../dockerfiles/buildContainerImage.sh -b -v "${VERSION}" -t "$BASE_IMAGE"-base
fi

for x in $EXTENSIONS; do
  echo "Building extension $x..."
  # Go into version folder
  cd "$x" || {
    echo "Could not find extension directory '$x'";
    exit 1;
  }

  if [ "$x" == "patching" ]; then 
    if [ "$( (ls patches/one_offs && ls patches/release_update) | wc -l)" -eq 0 ]; then
      echo "Patches Missing. Skipping Patching Extension"
      if [ "$EXTENSIONS" == "patching" ]; then
        exit
      fi
      cd ..
      continue
    fi
  fi

  # shellcheck disable=SC2086
  "${CONTAINER_RUNTIME}" build --force-rm=true --build-arg BASE_IMAGE="$BASE_IMAGE" \
       $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f $DOCKERFILE . || {
  echo ""
  echo "ERROR: Oracle Database Container Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the container build operation."
  exit 1
  }
  if "${CONTAINER_RUNTIME}" image inspect "${BASE_IMAGE}"-base >/dev/null 2>&1; then
      "${CONTAINER_RUNTIME}" tag "$BASE_IMAGE"-base "$IMAGE_NAME"-base
  fi
  BASE_IMAGE="$IMAGE_NAME"
  cd ..
done

"${CONTAINER_RUNTIME}" rmi -f "$BASE_IMAGE"-base

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
