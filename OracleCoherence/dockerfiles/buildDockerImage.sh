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

Usage: buildDockerImage.sh -v [version] -t [type] [-s]
Builds a base Docker Image for Oracle Coherence
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -t: type to build:
       Choose one of: standalone, quickinstall
   -s: skips the MD5 check of packages

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
VERSION="12.2.1"
SKIPMD5=0
while getopts "hst:v:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "t")
      DISTRIBUTION="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# Image Name
IMAGE_NAME="oracle/coherence:$VERSION-$DISTRIBUTION"

# Go into version folder
cd $VERSION

# Check distribution
if [ "$DISTRIBUTION" = "" ]; then
  usage
elif ! [ -e Dockerfile.$DISTRIBUTION ]; then
  echo "Enter a valid distribution"
fi

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
docker build --force-rm=true --no-cache=true -t $IMAGE_NAME -f Dockerfile.$DISTRIBUTION . || {
  echo "There was an error building the image."
  exit 1
}

echo ""

if [ $? -eq 0 ]; then
  echo "Coherence Docker Image for version $VERSION is ready to be extended: $IMAGE_NAME"
else
  echo "Coherence Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

