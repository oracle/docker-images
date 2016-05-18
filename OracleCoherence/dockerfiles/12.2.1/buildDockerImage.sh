#!/bin/bash
# 
# Since: October, 2014
# Author: Jonathan Knight
# Description: script to build a Docker image 
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-q | -s] [-s]
Builds a Docker Image for Oracle Coherence.
  
Parameters:
   -q: creates image based on 'quickinstall' distribution
   -s: creates image based on 'standalone' distribution
   -v: version to build

* select one distribution only: -q or -s

LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

# Parameters
QUICKINSTALL=0
STANDALONE=0
VERSION="12.2.1.0.0"
while getopts "hmv:qs" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "q")
      QUICKINSTALL=1
      ;;
    "s")
      STANDALONE=1
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
if [ $((QUICKINSTALL + STANDALONE)) -gt 1 ]; then
  usage
elif [ ${QUICKINSTALL} -eq 1 ]; then
  DISTRIBUTION="quickinstall"
elif [ ${STANDALONE} -eq 1 ]; then
  DISTRIBUTION="standalone"
else  
# If neither -s or -q were specified then determine which image we are building
# by which installer is present. If both the Standard and Quick installers are
# present then the Standard installer will be used.
  if [ -f "fmw_${VERSION}_coherence_Disk1_1of1.zip" ]; then
    DISTRIBUTION="standalone"
  elif [ -f "fmw_${VERSION}_coherence_quick_Disk1_1of1.zip" ]; then
    DISTRIBUTION="quickinstall"
  else
    echo "A valid distribution type argument has not been provided and no installer file can be found."
    exit 1
  fi
fi

# Image Name
IMAGE_NAME="oracle/coherence:$VERSION-$DISTRIBUTION"

echo "====================="

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME'..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true -t ${IMAGE_NAME} -f Dockerfile.${DISTRIBUTION} . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr ${BUILD_END} - ${BUILD_START}`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Coherence Docker Image for '${DISTRIBUTION}' version ${VERSION} is ready to be used:
    
    --> ${IMAGE_NAME}

  Build completed in ${BUILD_ELAPSED} seconds.

EOF
else
  echo "Coherence Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

