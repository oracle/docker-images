#!/bin/bash
#
# Since: October, 2014
# Author: monica.riccelli@oracle.com
# Description: script to build a Docker image for FMW Infrastructure
#
#Copyright (c) 2019, 2025, Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] -j [JDK version]  [-s] [-c]
Builds a Docker Image for Oracle FMW Infrastructure.

Parameters:
   -v: version to build. Required.
       Choose one of: 12.2.1.4 or 14.1.2.0
   -j: choose the JDK to create a 12.2.1.4 (JDK '8') or 14.1.2.0 (JDK '17' or '21') image
   -c: enables Docker image layer cache during build
   -s: skips the MD5 check of packages


LICENSE UPL 1.0

Copyright (c) 2019, 2025, Oracle and/or its affiliates.

EOF
exit 0
}

# Validate packages
validateJDK() {
   if [ "$VERSION" == "12.2.1.4" ]; then
      if [ "$JDKVER" != 8 ]; then
         echo "Fusion Middleware Infrastructure 12.2.1.4 supports JDK 8.  JDK version $JDKVER is not supported."
         exit 1
      fi
   elif [ "$VERSION" == "14.1.2.0" ]; then
      if [[ "$JDKVER" != 17 && "$JDKVER" != 21 ]]; then
         echo "Fusion Middleware Infrastructure 14.1.2.0 supports JDK 17 and 21.  JDK version $JDKVER is not supported."
         exit 1
      fi
   fi
}


# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum.$DISTRIBUTION
  md5_req="$?"
  if [ "$md5_req"  -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION. See *.download files for more information"
    exit $md5_req
  fi
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
VERSION="12.2.1.4"
SKIPMD5=0
NOCACHE=true
JDKVER=8

while getopts "hscv:j:" optname; do
case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      echo "Set- Skip md5sum"
      ;;
    "j")
      JDKVER="$OPTARG"
      echo "Set- JDK Version $JDKVER"
      ;;
    "c")
      NOCACHE=false
      ;;
    "v")
      VERSION="$OPTARG"
      echo "Set- FMW Infrastructure Version $VERSION"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done


# FMW Infrastructure Image Name
IMAGE_NAME="oracle/fmw-infrastructure:$VERSION"
echo "Image name: " $IMAGE_NAME



# Validate that the correct JDK is being used for the version of FMW Infrastructure
validateJDK

# Go into version folder
cd $VERSION || return

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi


echo "====================="

# Proxy settings
PROXY_SETTINGS=""
http_proxy=""
https_proxy=""
ftp_proxy=""
no_proxy=""
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
docker build --force-rm=$NOCACHE --no-cache=$NOCACHE $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`


status="$?"
if [ "$status" -eq 0 ]; then
cat << EOF
  Fusion Middleware Infrastructure Docker Image for version $VERSION is ready to be extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "FMW Infrastructure Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
