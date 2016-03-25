#!/bin/bash
# 
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to build a Docker image 
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-q | -s] [-s]
Builds a Docker Image for Oracle Coherence.
  
Parameters:
   -v: version to build. Required. 
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -q: creates image based on 'quickinstall' distribution
   -s: creates image based on 'standalone' distribution
   -m: skips the MD5 check of packages

* select one distribution only: -q or -s

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
QUICKINSTALL=0
STANDALONE=0
VERSION="12.2.1"
SKIPMD5=0
while getopts "hmv:qs" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "m")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "q")
      QUICKINSTALL=1
      ;;
    "s")
      STANDALONE=1
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# Which distribution to use?
if [ $((QUICKINSTALL + STANDALONE)) -gt 1 ]; then
  usage
elif [ $QUICKINSTALL -eq 1 ]; then
  DISTRIBUTION="quickinstall"
elif [ $STANDALONE -eq 1 ]; then
  DISTRIBUTION="standalone"
else  
  echo "A valid distribution type has not been provided."
  exit 1
fi

# Image Name
IMAGE_NAME="oracle/coherence:$VERSION-$DISTRIBUTION"

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
echo "Building image '$IMAGE_NAME'..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true -t $IMAGE_NAME -f Dockerfile.$DISTRIBUTION . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Coherence Docker Image for '$DISTRIBUTION' version $VERSION is ready to be used: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "Coherence Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

