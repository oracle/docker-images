#!/bin/bash

# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#set -x


usage() {
cat << EOF

Usage: buildContainerImage.sh [-hs] -v version -i installer [-m md5value]
Builds a Container Image for Oracle Tuxedo.
  
Parameters:
   -h: Help
   -v: Version to build. Required.
       Choose one of subdirectories. e.g. 21.1.0.0.0
   -s: Skips the MD5 check of packages.
   -i: Installer name. Required.
   -m: MD5 value expected. Required if -s not specified.
LICENSE UPL 1.0 

Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  if [ -z "$MD5VALUE" ]; then   # -m option is a MUST
    echo "You must specify $INSTALLER MD5 value with -m option"
    exit
  fi
  MD5="${MD5VALUE}  ${VERSION}/${INSTALLER}"
  echo "MD5 =  ${MD5}"
  MD5_CHECK="$(md5sum "${VERSION}"/"${INSTALLER}")"
  echo "MD5_CHECK =  ${MD5_CHECK}"

  if [ "$MD5" != "$MD5_CHECK" ]
  then
    echo "MD5 does not match! Download again!"
    exit
  fi
}

if [ "$#" -eq 0 ]; then usage; fi
echo "====================="
#

VERSION=
INSTALLER=
MD5VALUE=
SKIPMD5=0
while getopts "hsi:m:v:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "i")
     INSTALLER="$OPTARG"
      ;;
    "m")
     MD5VALUE="$OPTARG"
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildContainerImage.sh"
      ;;
  esac
done

if [ -z "$VERSION" ]; then   # -v option is a MUST
    echo "You must specify Tuxedo version with -v option"
    exit
fi

if [ -z "$INSTALLER" ]; then   # -i option is a MUST
    echo "You must specify installer name with -i option"
    exit
fi


if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

echo "====================="

if [ ! -e "${VERSION}"/"${INSTALLER}" ]
then
  echo "Download the Tuxedo ZIP Distribution and"
  echo "drop the file ${INSTALLER} in ${VERSION} folder before"
  echo "building this Tuxedo container image!"
  exit 
fi

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

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during build."
fi

echo "====================="

docker build  ${PROXY_SETTINGS:+"$PROXY_SETTINGS"} -t oracle/tuxedo:latest -t oracle/tuxedo:"${VERSION}" "${VERSION}"/
ret=$?
if [ "$ret" = "0" ]
    then
	echo ""
	echo "Tuxedo Container image is ready to be used. To create a container, run:"
	echo "docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedo:${VERSION}"
	echo "Note: \${LOCAL_DIR} is a local dir which used in Container image as external storage, it can be any dir."
    else
	echo "Build of Tuxedo Container image failed."
fi
