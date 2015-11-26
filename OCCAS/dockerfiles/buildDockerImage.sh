#!/bin/bash
# 
# Since: November, 2015
# Author: bruno.borges@oracle.com
# Author: ayuste@optaresolutions.com
# Description: script to build a Docker image for OCCAS

usage() {
cat << EOF
Usage: buildDockerImage.sh [-d | -g]
Builds a Docker Image for OCCAS.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)

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

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
VERSION="7.0"
while getopts "hdgv:" optname; do
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

# OCCAS Image Name
IMAGE_NAME="oracle/occas:$VERSION"

# Go into version folder
cd $VERSION

#checksumPackages

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
  echo "OCCAS Docker Image for  $VERSION is ready to be extended: $IMAGE_NAME"
else
  echo "OCCAS Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

