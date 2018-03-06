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
#ART Runtime installer, ART12.2.2 by default
ARTRT_INSTALLER=art122200_64_linux_x86_64.zip
CIT_INSTALLER=cobol-it-3.9.27-enterprise-64-x86_64-pc-linux-gnu.tar.gz
ORACLE_BASE=oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
ORACLE_SQLPLUS=oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm
ORACLE_DEVEL=oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm
ORACLE_PRECOMP=oracle-instantclient12.2-precomp-12.2.0.1.0-1.x86_64.rpm
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

if [ ! -e bin/${CIT_INSTALLER} ]
then
    echo "Download the Coboli-IT Distribution and"
    echo "drop the file ${CIT_INSTALLER} in ./bin/ folder before"
    echo "building this Tuxedo ART Docker container!"
    exit
fi

if [ ! -e bin/${ORACLE_BASE} ] && [ ! -e bin/${ORACLE_SQLPLUS} ] && \
   [ ! -e bin/${ORACLE_DEVEL} ] && [ ! -e ${ORACLE_PRECOMP} ]; then
  echo "Download the Oracle client ZIP Distribution and"
  echo "drop the file ${ORACLE_BASE} "
  echo "              ${ORACLE_SQLPLUS}"
  echo "              ${ORACLE_DEVEL}"
  echo "              ${ORACLE_PRECOMP} in ./bin/ folder before"
  echo "building this Tuxedo ART Docker container!"
  exit
fi

echo "====================="


if [ ! -e bin/${ARTRT_INSTALLER} ]
then
  echo "Download the Tuxedo ART Runtime ZIP Distribution and"
  echo "drop the file ${ARTRT_INSTALLER} in ./bin/ folder before"
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
docker build $PROXY_SETTINGS -t oracle/tuxedoartrt:${VERSION} .
if [ "$?" = "0" ]
    then
	echo ""
	echo "Tuxedo ART Docker image is ready to be used. To create a container, run:"
        echo "docker run  -d \\
              -v \${LOCAL_DIR}:/u01/oracle/user_projects \\
              -h arthost --name tuxedoartrt oracle/tuxedoartrt:12.2.2"
        echo "Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir."
    else
        echo "Build of Tuxedo ART Docker image failed."
fi

