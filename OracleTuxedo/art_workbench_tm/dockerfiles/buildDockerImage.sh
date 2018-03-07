#!/bin/bash
#set -x

usage() {
cat << EOF

Usage: buildDockerImage.sh [options]
Builds a Docker Image for Oracle Tuxedo ART. 
  
Parameters:
   -h: Help
   -v: Version to build. Required.
       Choose one of: $(for i in $(ls -d */|grep -v bin); do echo -n "${i%%/}  "; done)

LICENSE UPL 1.0

Copyright (c) 2017-2017 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}


if [ "$#" -eq 0 ]; then usage; fi
echo "====================="
#

VERSION=
ARTTM_INSTALLER=art_tm122200_64_linux_x86_64.zip
ARTWKB_INSTALLER=art_wb122200_64_linux_x86_64.zip
ECLIPSE_INSTALLER=eclipse-SDK-4.6.1-linux-gtk-x86_64.tar.gz
DERBY_INSTALLER=derby.tar.gz
PATCH_LIST=

while getopts "h:v:" optname; do
  case "$optname" in
    "h")
      usage
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

if [ -z "$VERSION" ]; then   # -v option is a MUST
    echo "You must specify Tuxedo version with -v option"
    exit
fi

if [ ! -e bin/${ECLIPSE_INSTALLER} ]
then
    echo "Download the Eclipse Distribution and"
    echo "drop the file ${ECLIPSE_INSTALLER} in ./bin/ folder before"
    echo "building this Tuxedo ART Docker container!"
    exit
fi

echo "====================="

if [ ! -e bin/${ARTWKB_INSTALLER} ]
then
    echo "Download the Tuxedo ART Workbench installer and"
    echo "drop the file ${ARTWKB_INSTALLER} in ./bin/ folder before"
    echo "building this Tuxedo ART Docker container!"
    exit
fi

if [ ! -e bin/${ARTTM_INSTALLER} ]
then
    echo "Download the Tuxedo ART Test Manager installer and"
    echo "drop the file ${ARTTM_INSTALLER} in ./bin/ folder before"
    echo "building this Tuxedo ART Docker container!"
    exit
fi

echo "====================="
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



# Fix up the locations of things
cp ${VERSION}/* .

docker build $PROXY_SETTINGS -t oracle/tuxedoartwkbtm:${VERSION} .
if [ "$?" = "0" ]
    then
	echo ""
	echo "Tuxedo ART Docker image is ready to be used. To create a container, run:"
	echo "docker run  -d \\
              -p 18080:8080 \\
              -v \${LOCAL_DIR}:/u01/oracle/user_projects \\
              -h artwkbtmhost --name tuxedoartwkbtm oracle/tuxedoartwkbtm:12.2.2 /sbin/init"
	echo "Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir."
    else
	echo "Build of Tuxedo ART Docker image failed."
fi

