#!/bin/bash
#
# Script to build a Docker image for Oracle SOA suite.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.

#=============================================================
usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version]

Builds a Docker Image for Oracle SOA/OSB/BPM
Parameters:
   -h: view usage
   -v: Release version to build. Required. Allowed values are
       12.2.1.2-soabpm

LICENSE CDDL 1.0 + GPL 2.0
Copyright (c) 2016-2017: Oracle and/or its affiliates. All rights reserved.
EOF
exit 0
}

#=============================================================
checksumPackages() {
  echo "INFO: Checking if required packages are present and valid..."
  md5sum -c *.download 2> /dev/null
  if [ "$?" -ne 0 ]; then
    echo "ERROR: MD5 for required packages to build this image"
    echo "       did not match. Please make sure to download"
    echo "       missing files in folder dockerfiles. See"
    echo "       Dockerfile for more information"
    exit $?
  fi
}

#=============================================================
#== MAIN starts here...
#=============================================================
VERSION="NONE"
SKIPMD5=0
while getopts "hsdgiv:t:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    *)
      # Should not occur
      echo "ERROR: Invalid argument. buildDockerImage.sh"
      ;;
  esac
done

if [ "${VERSION}" = "NONE" ]; then
  usage
fi

. ../setenv.sh

versionOK=false
if [[ $VERSION =~ .*soabpm.* ]]
then
  suffix="-soabpm"
  QSVERSION=${VERSION%$suffix}
  IMAGE_NAME="${DC_REGISTRY_SOA}/middleware/soabpm:$QSVERSION-dev"
  DOCKERFILE_NAME=Dockerfile
  versionOK=true
fi

if [ "${versionOK}" = "false" ]; then
  echo "ERROR: Incorrect version ${VERSION} specified"
  usage
fi

# Go into version folder
cd $VERSION

if [ ! "${SKIPMD5}" -eq 1 ]; then
  checksumPackages
else
  echo "INFO: Skipped MD5 checksum."
fi

# Proxy settings - Set your own proxy environment
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="--build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
buildCmd="docker build $BUILD_OPTS --force-rm=true $PROXY_SETTINGS -t $IMAGE_NAME -f $DOCKERFILE_NAME ."

echo "INFO: Image      : $IMAGE_NAME"
echo "INFO: Proxy      : $PROXY_SETTINGS"
echo "INFO: BUILD_OPTS : ${BUILD_OPTS}"
echo "INFO: CWD        : ${VERSION}"
echo "INFO: Build Command"
echo "  [${buildCmd}]"
echo " "
read -p "INFO: Ctrl-C to abort or Press any key to continue..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
${buildCmd} || {
  echo "ERROR: There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
  cat << EOF
INFO: Oracle SOA suite Docker Image for version: $VERSION 
      is ready to be extended.
      --> $IMAGE_NAME
INFO: Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "ERROR: Oracle SOA Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
