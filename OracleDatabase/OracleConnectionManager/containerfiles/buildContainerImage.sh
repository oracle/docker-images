#!/bin/bash
# shellcheck disable=SC2045,SC2154,SC2164,SC2320
#
#############################
# Copyright (c) 2024-2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
#
#

usage() {
  cat << EOF

Usage: buildDockerImage.sh -v [version] [-i] [-t] [-o] [Docker build option]
Builds a Docker Image for Oracle Connection Manager.

Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -i: ignores the MD5/SHA256 checksums
   -t: user defined image name and tag (e.g., image_name:tag)
   -o: passes on Docker/Podman build option (e.g., --build-arg INSTALL_FILE_1=<zip>)

LICENSE UPL 1.0

Copyright (c) 2014-2026 Oracle and/or its affiliates. All rights reserved.

EOF
  exit 0
}

# Validate packages (Checksum may contain MD5 or SHA256 digests)
checksumPackages() {
  local checksum_file="Checksum"
  local hash_algo="md5"
  local check_cmd="md5sum"
  local sample_hash

  if [ ! -f "${checksum_file}" ]; then
    echo "Checksum file ${checksum_file} not found."
    exit 1
  fi

  # Detect digest type from first non-comment hash line (64 hex = SHA256, else MD5)
  sample_hash="$(awk '/^[[:xdigit:]]{32,}/{print $1; exit}' "${checksum_file}")"
  if [[ "${sample_hash}" =~ ^[[:xdigit:]]{64}$ ]]; then
    hash_algo="sha256"
    check_cmd="sha256sum"
  fi

  if hash "${check_cmd}" 2>/dev/null; then
    echo "Checking if required packages are present and valid (${hash_algo})..."
    # shellcheck disable=SC2086
    ${check_cmd} -c "${checksum_file}"
    # shellcheck disable=SC2181
    if [ "$?" -ne 0 ]; then
      echo "${hash_algo} for required packages to build this image did not match!"
      echo "Make sure to download missing files in folder $VERSION."
      exit $?
    fi
  else
    echo "Ignored checksum, '${check_cmd}' command not available."
  fi
}

##############
#### MAIN ####
##############

# Parameters
VERSION="23.26.0"
SKIPMD5=0
DOCKEROPS=""
while getopts "hiv:o:t:" optname; do
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
      DOCKEROPS="$OPTARG"
      ;;
    "t")
      IMAGE_NAME="$OPTARG"
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
if [ "$VERSION" = "23.26.0" ]; then IMAGE_NAME="oracle/client-cman:23.26ai"; else IMAGE_NAME="oracle/client-cman:$VERSION"; fi
# Go into version folder
cd "$VERSION" || exit 1

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Ignored checksum."
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
docker build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Containerfile . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Oracle Connection Manager Docker Image version $VERSION is ready to be extended:

    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF

else
  echo "Oracle Connection Manager Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
