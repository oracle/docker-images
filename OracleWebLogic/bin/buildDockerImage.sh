#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "$0" )" && pwd )"
. $SCRIPTS_DIR/setDockerEnv.sh $*

while getopts "hdf" optname
  do
    case "$optname" in
      "h")
        echo "Usage: buildDockerImage.sh [-d]"
        echo ""
        echo "    -d: creates image based on 'weblogic12c-developer' distribution, or 'weblogic12c-generic' if not present, by default."
        echo "    -f: flattens image, by removing intermediary layers"
        echo ""
        exit 0
        ;;
      "d")
	setup_developer
	;;
      "f")
        FLATTEN_IMAGE=true
        ;;
      *)
      # Should not occur
        echo "Unknown error while processing options inside buildDockerImage.sh"
        ;;
    esac
  done


DOCKER_SCRIPTS_HOME=$SCRIPTS_DIR/../

echo "Building image '$IMAGE_NAME' based on distribution '$DISTRIBUTION'..."
 
# GO INTO DISTRIBUTION FOLDER
cd $DOCKER_SCRIPTS_HOME/$DISTRIBUTION

# Validate Java Package
if [ ! -e $JAVA_PKG ]
then
  echo "====================="
  echo "Download the Oracle JDK ${JAVA_VERSION} RPM for 64 bit and"
  echo "drop the file $JAVA_PKG in folder '$DISTRIBUTION' before"
  echo "building this image!"
  exit
fi


check_md5 $JAVA_PKG $JAVA_PKG_MD5
if [ "$?" -ne 0 ]
then
  echo "MD5 for $JAVA_PKG does not match! Download again!"
  exit
fi

#
# Validate WLS Package
if [ ! -e $WLS_PKG ]
then
  echo "====================="
  echo "Download the WebLogic 12c installer and"
  echo "drop the file $WLS_PKG in this folder before"
  echo "building this WLS Docker image!"
  exit 
fi

check_md5 $WLS_PKG $WLS_PKG_MD5
if [ "$?" -ne 0 ]
then
  echo "MD5 for $WLS_PKG does not match! Download again!"
  exit
fi

echo "====================="

# BUILD THE IMAGE
docker build --force-rm=true --no-cache=true --rm=true -t $IMAGE_NAME .

flatten_image() {
  if [ ! $FLATTEN_IMAGE ]
  then
    return 0
  fi
  echo "Flatten image flag found. Will flat this image..."
  docker tag $IMAGE_NAME ${IMAGE_NAME}-flatten
  CONTAINER=$(docker run -d ${IMAGE_NAME}-flatten echo)
  docker export $CONTAINER | docker import - $IMAGE_NAME
  docker rm -f $CONTAINER
  docker rmi -f ${IMAGE_NAME}-flatten
}

if [ $? -eq 0 ]
then
  flatten_image
  if [ $? -eq 0 ]
  then
    echo ""
    echo "WebLogic Docker Container is ready to be used. To start, run 'dockWebLogic.sh'"
  else
    echo ""
    echo "There was an error trying to flatten the image. Please try without the '-f' flag"
  fi
else
  echo ""
  echo "WebLogic Docker Container was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
