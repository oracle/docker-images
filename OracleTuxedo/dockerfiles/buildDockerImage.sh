#!/bin/bash
#set -x

usage() {
cat << EOF

Usage: buildDockerImage.sh [-hs] -v version -i installer [-m md5value]
Builds a Docker Image for Oracle Tuxedo.
  
Parameters:
   -h: Help
   -v: Version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -s: Skips the MD5 check of packages.
   -i: Installer name. Required.
   -m: MD5 value expected. Required if -s not specified.
LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2016-2016 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  if [ -z "$MD5VALUE" ]; then   # -m option is a MUST
    echo "You must specify "$INSTALLER" MD5 value with -m option"
    exit
  fi
  MD5="${MD5VALUE}  ${INSTALLER}"
  MD5_CHECK="`md5sum ${INSTALLER}`"

  if [ "$MD5" != "$MD5_CHECK" ]
  then
    echo "MD5 does not match! Download again!"
    exit
  fi

#  md5sum -c Checksum.$DISTRIBUTION
#  if [ "$?" -ne 0 ]; then
#    echo "MD5 for required packages to build this image did not match!"
#    echo "Make sure to download missing files in folder $VERSION. See *.download files for more information"
#    exit $?
#  fi
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
      echo "Unknown error while processing options inside buildDockerImage.sh"
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

if [ ! -e ${INSTALLER} ]
then
  echo "Download the Tuxedo ZIP Distribution and"
  echo "drop the file ${INSTALLER} in this folder before"
  echo "building this Tuxedo Docker container!"
  exit 
fi

# You may need uncomment the following lines and RP file name if you need check the RP md5sum value:
#if [ ! -e p*_121300_Linux-x86-64.zip ]
#then
#  echo "Installing Tuxedo without any patches"
#fi

#MD5="3b311c87e921fa9df696bf74c39c3348  p19927652_121300_Linux-x86-64.zip"
#MD5_CHECK="`md5sum p19927652_121300_Linux-x86-64.zip`"
#
#if [ "$MD5" != "$MD5_CHECK" ]
#then
#  echo "MD5 does not match! Download again!"
#  exit
#fi

echo "====================="

# Fix up the locations of things
sh fix_locations.sh tuxedo.docker ${VERSION}/tuxedo${VERSION}.rsp.template >tuxedo${VERSION}.rsp
sh fix_locations.sh tuxedo.docker ${VERSION}/tuxedo${VERSION}_silent_install.sh.template >tuxedo${VERSION}_silent_install.sh
sh fix_locations.sh tuxedo.docker ${VERSION}/Dockerfile >Dockerfile

docker build -t oracle/tuxedo:${VERSION} .
if [ "$?" = "0" ]
    then
	echo ""
	echo "Tuxedo Docker image is ready to be used. To create a container, run:"
	echo "docker run -i -t oracle/tuxedo:${VERSION} /bin/bash"
    else
	echo "Build of Tuxedo Docker image failed."
fi

