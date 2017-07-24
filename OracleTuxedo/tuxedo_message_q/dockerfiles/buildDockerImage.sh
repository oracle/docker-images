#!/bin/bash
#set -x

usage() {
cat << EOF

Usage: buildDockerImage.sh [-h] -v version 
Builds a Docker Image for Oracle Tuxedo.
  
Parameters:
   -h: Help
   -v: Version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}


if [ "$#" -eq 0 ]; then usage; fi
echo "====================="
#

VERSION=
INSTALLER=
MD5VALUE=
SKIPMD5=0
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
    echo "You must specify Tuxedo Message Queue version with -v option"
    exit
fi

echo "====================="

if [ ! -e ${VERSION}/${INSTALLER} ]
then
  echo "Download the Tuxedo Message Queue ${VERSION} ZIP Distribution and"
  echo "drop the file ${INSTALLER} in ${VERSION}/ folder before"
  echo "building this Tuxedo Message Queue Docker container!"
  exit 
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

echo "====================="

docker build $PROXY_SETTINGS -t oracle/tuxedotmq:${VERSION} ${VERSION}/
if [ "$?" = "0" ]
    then
	echo ""
	echo "Tuxedo TMQ Docker image is ready to be used. To create a container, run:"
	echo "docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotmq:${VERSION}"
	echo "Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir."
    else
	echo "Build of Tuxedo TMQ Docker image failed."
fi
