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
   -w: Tuxedo ART Workbench installer. Optional, Tuxedo ART Workbench 12.2.2 installer by default.
   -t: Tuxedo ART TestManager installer. Optional, Tuxedo ART Test Manager 12.2.2 installer by default.
   -e: Eclipse installer. Optional, eclipse-SDK-4.6.1 by default.
   -p: Tuxedo and ART Workbench, and ART Test Manager patches. Optional.
       For example, -p p26126370_122200_Linux-x86-64.zip,p26277335_122200_Linux-x86-64.zip
       which will install Tuxedo ART Workbench RP16 and Tuxedo ART Test Manager RP03

LICENSE CDDL 1.0 + GPL 2.0

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

while getopts "h:w:t::e:p:v:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "w")
      ARTWKB_INSTALLER="$OPTARG"
      ;;
    "t")
      ARTTM_INSTALLER="$OPTARG"
      ;;
    "e")
      ECLIPSE_INSTALLER="$OPTARG"
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

if [ ! -e bin/${ECLIPSE_INSTALLER} ]
then
    echo "Download the Eclipse Distribution and"
    echo "drop the file ${ECLIPSE_INSTALLER} in ./bin/ folder before"
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
cp ${VERSION}/*.rsp ${VERSION}/init.sh .
sed -e "s:@ARTTM_PKG@:${ARTTM_INSTALLER}:g" \
    -e "s:@ARTWKB_PKG@:${ARTWKB_INSTALLER}:g" \
    -e "s:@ECLIPSE_PKG@:${ECLIPSE_INSTALLER}:g" \
    -e "s:@COPY_PATCHFILE@:${PATCH_FILE}:g" \
    -e "s:@PATCH_FILE_LIST@:${PATCH_FILE_LIST}:g" \
    ${VERSION}/Dockerfile.template > Dockerfile

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

