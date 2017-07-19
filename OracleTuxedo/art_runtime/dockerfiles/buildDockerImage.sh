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
   -c: Cobol-IT installer. Optional, CIT3.9.27 installer by default.
   -r: Tuxedo ART Runtime installer. Optional, Tuxedo ART Runtime12.2.2 installer by default.
   -p: Tuxedo and ART Runtime patches. Optional.
       For example, -p p25442020_122200_Linux-x86-64.zip,p25671402_122200_Linux-x86-64.zip
       which will install Tuxedo ART CICS RP05 and Tuxedo ART Batch RP11

LICENSE CDDL 1.0 + GPL 2.0

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

while getopts "h:c:r:p:v:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "c")
      CIT_INSTALLER="$OPTARG"
      ;;
    "r")
      ARTRT_INSTALLER="$OPTARG"
      ;;
    "p")
      PATCH_LIST="$OPTARG"
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
    echo "Download the Cobol-IT Distribution and"
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

if [ ! -z "$PATCH_LIST" ]; then   # -p option is an OPTIONAL
    PATCH_FILE="" 
    PATCH_FILE_LIST="" 
    OLD_IFS="$IFS" 
    IFS="," 
    arrPatch=($PATCH_LIST)
    for s in ${arrPatch[@]}
    do
        if [ ! -e bin/${s} ]
        then
            echo "Download the patch file and"
            echo "drop the file ${s} in ./bin/ folder before"
            echo "building this Tuxedo ART Docker container!"
            exit
        fi
        PATCH_FILE=${PATCH_FILE}"bin/$s "
        PATCH_FILE_LIST=${PATCH_FILE_LIST}"$s "
    done
    IFS="$OLD_IFS"
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
cp ${VERSION}/*.rsp ${VERSION}/init.sh .
sed -e "s:@ARTRT_PKG@:${ARTRT_INSTALLER}:g" \
    -e "s:@CIT_PKG@:${CIT_INSTALLER}:g" \
    -e "s:@COPY_PATCHFILE@:${PATCH_FILE}:g" \
    -e "s:@PATCH_FILE_LIST@:${PATCH_FILE_LIST}:g" \
    ${VERSION}/Dockerfile.template > Dockerfile

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

