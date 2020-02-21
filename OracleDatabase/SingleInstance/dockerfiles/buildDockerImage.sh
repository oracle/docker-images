#!/bin/bash -e
# 
# Since: April, 2016
# Author: gerald.venzl@oracle.com
# Description: Build script for building Oracle Database Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
  cat << EOF

Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-i] [-o] [Docker build option]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -e: creates image based on 'Enterprise Edition'
   -s: creates image based on 'Standard Edition 2'
   -x: creates image based on 'Express Edition'
   -i: ignores the MD5 checksums
   -o: passes on Docker build option

* select one edition only: -e, -s, or -x

LICENSE UPL 1.0

Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.

EOF

}

# Validate packages
checksumPackages() {
  if hash md5sum 2>/dev/null; then
    echo "Checking if required packages are present and valid..."   
    if ! md5sum -c "Checksum.$EDITION"; then
      echo "MD5 for required packages to build this image did not match!"
      echo "Make sure to download missing files in folder $VERSION."
      exit 1;
    fi
  else
    echo "Ignored MD5 sum, 'md5sum' command not available.";
  fi
}

# Check Podman version
checkPodmanVersion() {
  # Get Podman version
  echo "Checking Podman version."
  PODMAN_VERSION=$(docker info --format '{{.host.BuildahVersion}}')
  # Remove dot in Podman version
  PODMAN_VERSION=${PODMAN_VERSION//./}

  if [ -z "$PODMAN_VERSION" ]; then
    exit 1;
  elif [ "$PODMAN_VERSION" -lt "${MIN_PODMAN_VERSION//./}" ]; then
    echo "Podman version is below the minimum required version $MIN_PODMAN_VERSION"
    echo "Please upgrade your Podman installation to proceed."
    exit 1;
  fi
}

# Check Docker version
checkDockerVersion() {
  # Get Docker Server version
  echo "Checking Docker version."
  DOCKER_VERSION=$(docker version --format '{{.Server.Version | printf "%.5s" }}'|| exit 0)
  # Remove dot in Docker version
  DOCKER_VERSION=${DOCKER_VERSION//./}

  if [ -z "$DOCKER_VERSION" ]; then
    # docker could be aliased to podman and errored out (https://github.com/containers/libpod/pull/4608)
    checkPodmanVersion
  elif [ "$DOCKER_VERSION" -lt "${MIN_DOCKER_VERSION//./}" ]; then
    echo "Docker version is below the minimum required version $MIN_DOCKER_VERSION"
    echo "Please upgrade your Docker installation to proceed."
    exit 1;
  fi;
}

##############
#### MAIN ####
##############

# Parameters
ENTERPRISE=0
STANDARD=0
EXPRESS=0
VERSION="19.3.0"
SKIPMD5=0
DOCKEROPS=""
MIN_DOCKER_VERSION="17.09"
MIN_PODMAN_VERSION="1.6.0"
DOCKERFILE="Dockerfile"

if [ "$#" -eq 0 ]; then
  usage;
  exit 1;
fi

while getopts "hesxiv:o:" optname; do
  case "$optname" in
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
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

checkDockerVersion

# Which Edition should be used?
if [ $((ENTERPRISE + STANDARD + EXPRESS)) -gt 1 ]; then
  usage
elif [ $ENTERPRISE -eq 1 ]; then
  EDITION="ee"
elif [ $STANDARD -eq 1 ]; then
  EDITION="se2"
elif [ $EXPRESS -eq 1 ]; then
  if [ "$VERSION" == "18.4.0" ]; then
    EDITION="xe"
    SKIPMD5=1
  elif [ "$VERSION" == "11.2.0.2" ]; then
    EDITION="xe"
    DOCKEROPS="--shm-size=1G $DOCKEROPS";
  elif [ "$VERSION" == "18.4.0" ]; then
    EDITION="xe"
  else
    echo "Version $VERSION does not have Express Edition available.";
    exit 1;
  fi;
fi;

# Which Dockerfile should be used?
if [ "$VERSION" == "12.1.0.2" ] || [ "$VERSION" == "11.2.0.2" ] || [ "$VERSION" == "18.4.0" ]; then
  DOCKERFILE="$DOCKERFILE.$EDITION"
fi;

# Oracle Database Image Name
IMAGE_NAME="oracle/database:$VERSION-$EDITION"

# Go into version folder
cd "$VERSION" || {
  echo "Could not find version directory '$VERSION'";
  exit 1;
}

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Ignored MD5 checksum."
fi
echo "=========================="
echo "DOCKER info:"
docker info
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
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true \
       $DOCKEROPS $PROXY_SETTINGS --build-arg DB_EDITION=$EDITION \
       -t $IMAGE_NAME -f $DOCKERFILE . || {
  echo ""
  echo "ERROR: Oracle Database Docker Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the docker build operation."
  exit 1
}

# Remove dangling images (intermitten images with tag <none>)
yes | docker image prune > /dev/null

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo ""

cat << EOF
  Oracle Database Docker Image for '$EDITION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

