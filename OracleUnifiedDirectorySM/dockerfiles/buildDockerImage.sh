#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# Description: script to build a Docker image for Oracle Unified Directory Service Manager
#

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] -d [domain-type] [-s]
Builds a Docker Image for Oracle Unified Directory Service Manager

Parameters:
   -h: view usage
   -v: Release version to build. Required. E.g 12.2.1.4.0
   -s: skips the MD5 check of packages (DEFAULT)

Copyright (c) 2020: Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0 as shown at 
https://oss.oracle.com/licenses/upl.
EOF
exit 0
}


#=============================================================
checkFilePackages() {
  echo "INFO: Checking if required packages are present..."

  jarList=`grep -v -e "^#.*" oud.download | awk '{print $2}'`
  for jar in ${jarList}; do
     if [ -s ${jar} ]; then
       echo "INFO:   ${jar} found. Proceeding..."
     else
       cat > /dev/stderr <<EOF

ERROR: Install Distribution ${jar} not found in
  `pwd`
  The following are required to proceed.
EOF
       cat oud.download
       exit 1
     fi
  done
}

#=============================================================
checksumPackages() {
  if [ "${SKIPMD5}" -eq 1 ]; then
    echo "INFO: Skipped MD5 checksum as requested"
    return
  fi

  echo "INFO: Checking if required packages are valid..."

  md5sum --quiet -c oud.download 2> /dev/null
  if [ "$?" -ne 0 ]; then
    cat <<EOF

ERROR: MD5 for required packages to build the ${VERSION}
       image did not match. Please make sure to download
       or check the files in the ${VERSION} folder.
EOF
    cat oud.download
    echo " "
    exit $?
  fi
}

#Parameters
VERSION="NONE"
SKIPMD5=0
while getopts "hsv:" optname; do
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
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

if [ "${VERSION}" = "NONE" ]; then
  usage
fi

. ../setenv.sh

# OUD Image Name
IMAGE_NAME="oracle/oudsm:$VERSION"
DOCKERFILE_NAME="Dockerfile"

versionOK=false
if [ ${VERSION} = 12.2.1.4.0 ]
then
  if [ ! -z "${DC_REGISTRY}" ]
  then
    IMAGE_NAME="${DC_REGISTRY}/oracle/oudsm:$VERSION"
  fi
  versionOK=true
  THEDIR=${VERSION}
fi

if [ "${versionOK}" = "false" ]; then
  echo "ERROR: Incorrect version ${VERSION} specified"
  usage
else
  if [ ! -d ${THEDIR} ]; then
    echo "ERROR: Incorrect version ${THEDIR} directory not found"
    usage
  fi
fi

# Go into version folder
cd $VERSION
echo  "version --> $VERSION  "

checkFilePackages
checksumPackages

# Proxy settings
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
  Oracle Unified Directory Service Manager Docker Image for version: $VERSION is ready to be extended.

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "Oracle Unified Directory Service Manager Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
