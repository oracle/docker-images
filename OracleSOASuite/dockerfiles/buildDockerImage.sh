#!/bin/bash
#
# Script to build a Container image for Oracle SOA suite.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2016, 2025, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
#
#=============================================================
usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version]

Builds a Container Image for Oracle SOA/OSB
Parameters:
   -h: view usage
   -v: Release version to build. Required.
   -s: Skip checksum verification
   -p: Uses podman CLI to build the image. Option enabled only for 14.1.2.0

LICENSE Universal Permissive License (UPL), Version 1.0
Copyright (c) 2016-2025: Oracle and/or its affiliates.

EOF
exit $1
}

#=============================================================
checkFilePackages() {
  echo "INFO: Checking if required packages are present..."
  jarList=`grep -v -e "^#.*" install/soasuite.download | awk '{print $2}'`
  for jar in ${jarList}; do
     if [ -s ${jar} ]; then
       echo "INFO:   ${jar} found. Proceeding..."
     else
       cat > /dev/stderr <<EOF

ERROR: Install Distribution ${jar} not found in
  `pwd`
  The following are required to proceed.
EOF
       cat install/soasuite.download
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

  md5sum --quiet -c install/soasuite.download 2> /dev/null
  rc=$?
  if [ "$rc" -ne 0 ]; then
    cat <<EOF

ERROR: MD5 for required packages to build the ${VERSION}
       image did not match. Please make sure to download
       or check the files in the ${VERSION} folder.
EOF
    cat install/soasuite.download
    echo " "
    exit $rc
  fi
}

#=============================================================
#== MAIN starts here...
#=============================================================
VERSION="NONE"
SKIPMD5=0
while getopts "hsv:p" optname; do
  case "$optname" in
    "h")
      usage 0
      ;;
    "s")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "p")
      if [ "${VERSION}" != "14.1.2.0" ]; then
        usage
      fi

      BUILD_CLI=podman
      BUILD_OPTS="--format docker"
      ;;
    *)
      # Should not occur
      echo "ERROR: Invalid argument for buildDockerImage.sh"
      usage 1
      ;;
  esac
done

if [ "${VERSION}" = "NONE" ]; then
  usage
fi


. ../setenv.sh

IMAGE_NAME="oracle/soasuite:$VERSION"

if [ "${VERSION}" = "14.1.2.0" ]; then
  CONTAINERFILE_NAME=Containerfile
else
  CONTAINERFILE_NAME=Dockerfile
fi

THEDIR=${VERSION}

if [ ! -d ${THEDIR} ]; then
  echo "ERROR: Incorrect version ${THEDIR} . Directory with product version not found"
  usage
fi


# Go into version folder
cd "${THEDIR}" || exit 1

checkFilePackages
checksumPackages

# Proxy settings - Set your own proxy environment
if [ "${http_proxy:-}" != "" ]; then
  PROXY_SETTINGS="--build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy:-}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${no_proxy:-}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #

buildCmd="${BUILD_CLI:-docker} build $BUILD_OPTS --force-rm=true $PROXY_SETTINGS -t $IMAGE_NAME -f $CONTAINERFILE_NAME ."

cat > /dev/stdout <<EOF

General Information:
====================
INFO: Image Name : $IMAGE_NAME
INFO: Proxy      : $PROXY_SETTINGS
INFO: Build Opts : ${BUILD_OPTS}
INFO: Current Dir: ${THEDIR}
INFO: Build Command
${buildCmd}

EOF
read -p "INFO: Ctrl-C to abort or Press any key to continue..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
${buildCmd} || {
  echo "ERROR: There was an error building the image."
  exit 1
}
status=$?

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ ${status} -eq 0 ]; then
  cat << EOF
INFO: Oracle SOA suite Container Image for version: $VERSION
      is ready to be extended.
      --> $IMAGE_NAME
INFO: Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "ERROR: Oracle SOA Container Image was NOT successfully created. Check the output and correct any reported problems with the image build operation."
fi
