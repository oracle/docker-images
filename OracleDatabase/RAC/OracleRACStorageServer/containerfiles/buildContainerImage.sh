#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/baseImageMetadata.sh"

checkContainerRuntime() {
  CONTAINER_RUNTIME=$(which docker 2>/dev/null) ||
    CONTAINER_RUNTIME=$(which podman 2>/dev/null) ||
    { echo "No docker or podman executable found in your PATH"; exit 1; }
}
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
############################

usage() {
  cat << EOF

Usage: buildContainerImage.sh -v [version] [-o] [Podman build option]
Builds a Podman Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose "latest" version for Podman host machines
       Choose "ol7" version for legacy hosts
   -o: passes on Podman build option

#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

EOF
  exit 0
}

##############
#### MAIN ####
##############

# Parameters
VERSION="latest"
export SKIPMD5=0
DOCKEROPS=""

while getopts "hiv:o:" optname; do
  case "$optname" in
    "h")
      usage
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
      echo "Unknown error while processing options inside buildContainerImage.sh"
      ;;
  esac
done

# Oracle Database Image Name
IMAGE_NAME="oracle/rac-storage-server:$VERSION"
checkContainerRuntime
if [[ "${VERSION}" == ol7* ]]; then BASE_IMAGE_DEFAULT="oraclelinux:7-slim"; else BASE_IMAGE_DEFAULT="oraclelinux:8"; fi
resolve_base_image_metadata "${VERSION}" "${BASE_IMAGE_DEFAULT}" "${DOCKEROPS}"
DOCKEROPS="${DOCKEROPS} ${BASE_IMAGE_BUILD_ARGS}"
# Go into version folder
cd "$VERSION" || exit 1

echo "=========================="
echo "Container runtime info:"
"${CONTAINER_RUNTIME}" info
echo "=========================="

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
# shellcheck disable=SC2154
if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
# shellcheck disable=SC2086
"${CONTAINER_RUNTIME}" build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Containerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_STATUS=$?
BUILD_END=$(date '+%s')
# shellcheck disable=SC2154,SC2003
BUILD_ELAPSED=$((BUILD_END - BUILD_START))

echo ""
# shellcheck disable=SC2181,SC2320
if [ ${BUILD_STATUS} -eq 0 ]; then
cat << EOF
  Oracle RAC Storage Server Container Image version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

else
  echo "Oracle RAC Storage Server image was NOT successfully created. Check the output and correct any reported problems with the container build operation."
fi
