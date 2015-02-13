#!/bin/bash
# 
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to build a Docker image for WebLogic

usage() {
cat << EOF
Usage: buildDockerImage.sh -v version [-d]
Builds a Docker Image for WebLogic.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -d: creates image based on 'developer' distribution, or 'generic' if ommitted.

LICENSE CDDL 1.0 + GPL 2.0
EOF
exit 0
}

if [ "$#" -eq 0 ]; then
    usage
fi

while getopts "hdfv:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "d")
      DEVELOPER=true
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo "You must inform a version to be built."
  echo "Example: ./buildDockerImage.sh -v 12.1.3"
  echo ""
  echo "Versions available:"
  for i in $(ls -d */); do echo " - ${i%%/}"; done
  exit 1
fi

# WebLogic Image Names
DEFAULT_IMAGE_NAME="oracle/weblogic:$VERSION"
DEFAULT_DEV_IMAGE_NAME="$DEFAULT_IMAGE_NAME-dev"

# Developer or Generic?
if [ $DEVELOPER ]; then
  DISTRIBUTION="developer"
  IMAGE_NAME="$DEFAULT_DEV_IMAGE_NAME"
else
  DISTRIBUTION="generic"
  IMAGE_NAME="$DEFAULT_IMAGE_NAME"
fi
  
# Go into version folder
cd $VERSION
  
# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum -c Checksum.$DISTRIBUTION
  if [ "$?" -ne 0 ]
  then
    echo "MD5 for required packages to build this image did not match!"
    exit $?
  fi
}

checksumPackages

echo "====================="

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' based on '$DISTRIBUTION' distribution..."

# BUILD THE IMAGE (replace all environment variables)
rm -f Dockerfile && ln -s Dockerfile.$DISTRIBUTION Dockerfile
docker build --force-rm=true --no-cache=true --rm=true -t $IMAGE_NAME . 
rm -f Dockerfile

if [ $? -ne 0 ]; then
  echo "There was an error building the image."
  exit $?
fi

echo ""
if [ $? -eq 0 ]; then
  echo "WebLogic Docker Image for '$DISTRIBUTION' $VERSION is ready to be extended: $IMAGE_NAME"
else
  echo "WebLogic Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

