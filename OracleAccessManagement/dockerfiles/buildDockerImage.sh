#!/bin/bash
#
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#
# Description: script to build a Docker image for Oracle Access Manager 
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#
usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] -d [domain-type] [-s]
Builds a Docker Image for Oracle OAM Suite .

Parameters:
   -h: view usage
   -v: Release version to build. Required. E.g 12.2.1.4.0
   -d: Domain type to be built. Required for building the domain oam
   -s: skips the MD5 check of packages (DEFAULT)

LICENSE CDDL 1.0 + GPL 2.0
Copyright (c) 2016-2017: Oracle and/or its affiliates. All rights reserved.
EOF
exit 0
}


# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c *.download
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder dockerfiles. See *.download files for more information"
    exit $?
  fi
}

#Parameters
VERSION="12.2.1.4.0"
SKIPMD5=1
while getopts "hsdgiv:t:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "t")
      DOMAINTYPE="$OPTARG"
      echo "Domain Type selected is : "$DOMAINTYPE
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
         *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# OAM Image Name
IMAGE_NAME="oracle/oam:$VERSION"
DOCKERFILE_NAME="Dockerfile"


# Go into version folder
cd $VERSION
echo  "version --> $VERSION  "

# Proxy settings
PROXY_SETTINGS="--build-arg http_proxy=http://www-proxy.us.oracle.com:80"
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
echo "Proxy Settings '$PROXY_SETTINGS'"
# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')

docker build --force-rm=true --no-cache=true $PROXY_SETTINGS -t $IMAGE_NAME -f $DOCKERFILE_NAME . || {
  echo "There was an error building the image."
  exit 1
}

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle OAM suite Docker Image for version: $VERSION is ready to be extended.

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "Oracle OAM Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
