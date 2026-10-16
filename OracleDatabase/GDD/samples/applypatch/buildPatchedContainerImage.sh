#!/bin/bash
# shellcheck disable=SC2034,SC2045,SC2046,SC2154,SC2164,SC2320
#
# Copyright (c) 2022, Oracle and/or its affiliates
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# shellcheck disable=SC2045
# shellcheck disable=SC2034
# shellcheck disable=SC2164
# shellcheck disable=SC2154
# shellcheck disable=SC2046
# shellcheck disable=SC2320

checkContainerRuntime() {
  CONTAINER_RUNTIME=$(command -v podman 2>/dev/null) ||
    CONTAINER_RUNTIME=$(command -v docker 2>/dev/null) ||
    {
      echo "No docker or podman executable found in your PATH"
      exit 1
    }
}

usage() {
  cat << EOF

Usage: buildPatchedContainerImage.sh -v [version] -t [image_name:tag] -p [patch version] [-o] [container build option]
It builds a patched GSM container image

Parameters:
   -v: version to build
   -t: user-defined image name and tag
   -o: passes on container build option
   -p: patch label to be used for the tag

LICENSE UPL 1.0

Copyright (c) 2014,2022 Oracle and/or its affiliates.

EOF
  exit "${1:-0}"
}

##############
#### MAIN ####
##############

# No arguments: report an error.
if [ "$#" -eq 0 ]; then
  usage 1 >&2
fi

# Parameters
# shellcheck disable=SC2034
LATEST="latest"
VERSION=''
IMAGE_NAME=""
PATCHLABEL="patch"
DOCKEROPS=""

while getopts "hv:t:p:o:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "t")
      IMAGE_NAME="$OPTARG"
      ;;
    "p")
      PATCHLABEL="$OPTARG"
      ;;
    "o")
      DOCKEROPS="$OPTARG"
     ;;
    "?")
      usage 1 >&2
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildPatchedContainerImage.sh"
      ;;
  esac
done

if [[ -z "$VERSION" || -z "$PATCHLABEL" ]]; then
  usage 1 >&2
fi

# Oracle Database Image Name
IMAGE_NAME="${IMAGE_NAME:-localhost/oracle/gsm:${VERSION}-${PATCHLABEL}}"

# Go into version folder
# shellcheck disable=SC2164
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/${LATEST}" || exit 1

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
# Select Podman or Docker before using CONTAINER_RUNTIME.
checkContainerRuntime

echo "Building image '$IMAGE_NAME' using '$CONTAINER_RUNTIME' ..."
BUILD_START=$(date '+%s')

# shellcheck disable=SC2086
"${CONTAINER_RUNTIME}" build --no-cache=true $DOCKEROPS \
    --build-arg VERSION="$VERSION" \
    $PROXY_SETTINGS \
    -t "$IMAGE_NAME" -f Containerfile . || {
  echo "ERROR: Failed to build patched GSM image '${IMAGE_NAME}'." >&2
  echo "Review the build output above for the cause." >&2
  exit 1
}

BUILD_END=$(date '+%s')
BUILD_ELAPSED=$((BUILD_END - BUILD_START))

cat <<EOF

Oracle patched GSM container image built successfully.

  Image        : ${IMAGE_NAME}
  Base version : ${VERSION}
  Build time   : ${BUILD_ELAPSED} seconds

EOF
