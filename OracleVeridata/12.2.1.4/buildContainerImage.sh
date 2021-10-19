#!/bin/bash
#
# Since: February, 2020
# Description: script to build a Docker image for Oracle GoldenGate Veridata.
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020-2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
usage() {
cat << EOF

Usage: buildContainerImage.sh -v [version]
Builds a Docker container for Oracle GoldenGate Veridata.

Parameters:
   -v: Release version to build. Default is 12.2.1.4.0
   -i: OGG Veridata Installer zip file
   -f: FMW Release version.Default is 12.2.1.4-210701
   -p: Patch file
   -h: Help



Copyright (c) 2020-2021 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

EOF
exit 0
}


# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder . See *.zip files for more information"
    exit $?
  fi
}

if [ "$#" -eq 0 ]; then usage; fi

#Parameters
VERSION="12.2.1.4.0"
FMW_VERSION="12.2.1.4-210701"
SKIPMD5=1
PATCH_FILE=""
VDT_INSTALLER=""



while getopts "hc:v:i:f:p:" optname; do
  case ${optname} in
    v)
      VERSION="$OPTARG"
      ;;
    i)
      VDT_INSTALLER="$OPTARG"
      ;;
    f)
      FMW_VERSION="$OPTARG"
      ;;
    p)
      PATCH_FILE="$OPTARG"
      ;;
    c)
      SKIPMD5=0
      ;;
    h)
      usage
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildContainerImage.sh"
      ;;
  esac
done

echo $VERSION
echo $VDT_INSTALLER
echo $PATCH_FILE


# OGG Veridata Image Name
IMAGE_NAME="oracle/oggvdt:$VERSION"
INSTALLER_VERSION="12.2.1.4.0"



if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

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
  echo "Proxy settings were found and will be used during build."
fi

if [ "$PATCH_FILE" == "" ]; then
  echo "WARNING !! Apply the latest Patch"
fi

if [ -z "${owner_group}" ]; then
  owner_group="oracle:oracle"
  export owner_group="$owner_group"
fi

export VERIDATA_VERSION="$VERSION"
export FMW_VERSION="$FMW_VERSION"
export PATCH_FILE="$PATCH_FILE"
# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."
echo "Proxy Settings '$PROXY_SETTINGS'"
# BUILD THE IMAGE (replace all environment variables)


BUILD_START=$(date '+%s')

docker build --build-arg VERIDATA_VERSION=${VERIDATA_VERSION} --build-arg INSTALLER_VERSION=${INSTALLER_VERSION} --build-arg INSTALLER=${VDT_INSTALLER} --build-arg FMW_VERSION=${FMW_VERSION} --build-arg PATCH_FILE=${PATCH_FILE} --build-arg OWNER_GROUP=${owner_group} --force-rm=true --no-cache=true $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle GoldenGate Veridata Docker Image for version: $VERSION.

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "Oracle GoldenGate Veridata container image was not successfully created. Check the output and correct any reported problems with the build operation."
fi
