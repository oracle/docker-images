#!/bin/bash
#
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2018-2025 Oracle and/or its affiliates.
#
# shellcheck disable=SC2154
usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-e | -s | -x] [-i] [-o] [container build option]
It builds a container image for a DNS server

Parameters:
   -v: version to build
       Choose one of: $(printf "%s  " */ | sed 's#/##g')
   -o: passes on container build option

LICENSE UPL 1.0

Copyright (c) 2014,2021 Oracle and/or its affiliates.

EOF
  exit 0
}


checksumPackages() {
  if [ "$SKIPMD5" -eq 1 ]; then
    echo "Skipping MD5 checksum verification."
    return 0
  fi

  if command -v md5sum >/dev/null 2>&1; then
    echo "Checking if required packages are present and valid..."
    md5sum -c Checksum
    rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "MD5 for required packages to build this image did not match!"
      echo "Make sure to download missing files in folder $VERSION."
      exit "$rc"
    fi
  else
    echo "Ignored MD5 sum, 'md5sum' command not available."
  fi
}


##############
#### MAIN ####
##############

if [ "$#" -eq 0 ]; then
  usage;
fi

# Parameters
VERSION="latest"
SKIPMD5=0
PODMANOPS=""

while getopts "hiv:o:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "i")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "o")
      PODMANOPS="$OPTARG"
      ;;
    "?")
      usage;
      # shellcheck disable=SC2317
      exit 1;
      ;;
    *)
      echo "Unknown error while processing options inside buildPodmanImage.sh"
      ;;
  esac
done

# Oracle Database Image Name
IMAGE_NAME="oracle/rac-dnsserver:$VERSION"

# Go into version folder
cd "$VERSION" || exit

echo "=========================="
echo "PODMAN info:"
podman info
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
BUILD_START=$(date +%s)

if ! podman build --force-rm=true --no-cache=true \
     $PODMANOPS $PROXY_SETTINGS \
     -t "$IMAGE_NAME" -f Containerfile .; then
  echo "There was an error building the image."
  exit 1
fi

BUILD_END=$(date +%s)
BUILD_ELAPSED=$((BUILD_END - BUILD_START))

cat << EOF

  Oracle Database Container Image for Real Application Clusters (RAC) version $VERSION is ready to be extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF