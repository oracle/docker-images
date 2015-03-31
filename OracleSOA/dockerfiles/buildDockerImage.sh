#!/bin/bash
# 
# Since: October, 2014
# Author: quilcate.jorge@gmail.com
# Description: script to build a Docker image for Oracle SOA

usage() {
cat << EOF
Usage: buildDockerImage.sh
Builds a Docker Image for Oracle SOA Suite.

LICENSE CDDL 1.0 + GPL 2.0
EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    exit $?
  fi
}

# SOA Suite Image Names and Version
VERSION="12.1.3"
DEFAULT_IMAGE_NAME="oracle/soa:$VERSION"
IMAGE_NAME="oracle/soa:$VERSION-dev"

# Go into version folder
cd $VERSION

checksumPackages

echo "====================="

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME'..."

# BUILD THE IMAGE (replace all environment variables)
docker build --force-rm=true --no-cache=true --rm=true -t $IMAGE_NAME . 

if [ $? -ne 0 ]; then
  echo "There was an error building the image."
  exit $?
fi

echo ""

if [ $? -eq 0 ]; then
  echo "SOA Suite Docker Image $VERSION is ready to be extended: $IMAGE_NAME"
else
  echo "SOA Suite Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

