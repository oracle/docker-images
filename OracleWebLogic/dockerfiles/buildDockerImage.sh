#!/bin/bash
# 
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to build a Docker image for WebLogic
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-d | -g | -i] [-s]
Builds a Docker Image for Oracle WebLogic.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -d: creates image based on 'developer' distribution
   -g: creates image based on 'generic' distribution
   -i: creates image based on 'infrastructure' distribution
   -s: skips the MD5 check of packages

* use either -d or -g, obligatory.

LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum.$DISTRIBUTION
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION. See *.download files for more information"
    exit $?
  fi
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
DEVELOPER=0
GENERIC=0
INFRASTRUCTURE=0
VERSION="12.2.1"
SKIPMD5=0
while getopts "hsdgiv:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "d")
      DEVELOPER=1
      ;;
    "g")
      GENERIC=1
      ;;
    "i")
      INFRASTRUCTURE=1
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

# Which distribution to use?
if [ $((DEVELOPER + GENERIC + INFRASTRUCTURE)) -gt 1 ]; then
  usage
elif [ $DEVELOPER -eq 1 ]; then
  DISTRIBUTION="developer"
elif [ $GENERIC -eq 1 ]; then
  DISTRIBUTION="generic"
elif [ $INFRASTRUCTURE -eq 1 ] && [ "$VERSION" = "12.1.3" ]; then
  echo "Version 12.1.3 does not have infrastructure distribution available."
  exit 1
else
  DISTRIBUTION="infrastructure"
fi

# WebLogic Image Name
IMAGE_NAME="oracle/weblogic:$VERSION-$DISTRIBUTION"

# Go into version folder
cd $VERSION

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

echo "====================="

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
docker build --force-rm=true --no-cache=true -t $IMAGE_NAME -f Dockerfile.$DISTRIBUTION . || {
  echo "There was an error building the image."
  exit 1
}

echo ""

if [ $? -eq 0 ]; then
  echo "WebLogic Docker Image for '$DISTRIBUTION' version $VERSION is ready to be extended: $IMAGE_NAME"
else
  echo "WebLogic Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

