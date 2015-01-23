#!/bin/bash
DOCKING="false"
SCRIPTS_DIR="$( cd "$( dirname "$0" )" && pwd )"
. $SCRIPTS_DIR/setDockerEnv.sh  

cd $SCRIPTS_DIR/..

JAVA_VERSION="8u25"
JAVA_PKG="config/jdk-${JAVA_VERSION}-linux-x64.rpm"
JAVA_PKG_MD5="6a8897b5d92e5850ef3458aa89a5e9d7"
FMW_PKG="config/fmw_12.1.3.0.0_coherence_Disk1_1of1.zip"
FMW_PKG_MD5="a4affba654a0664284e6a454341f3e93"

# Validate Java Package
echo "====================="

if [ ! -e $JAVA_PKG ]
then
  echo "Download the Oracle JDK ${JAVA_VERSION} RPM for 64 bit and"
  echo "drop the file $JAVA_PKG in this folder before"
  echo "building this image!"
  exit
fi

MD5="$JAVA_PKG_MD5  $JAVA_PKG"
MD5_CHECK="`md5sum $JAVA_PKG`"

if [ "$MD5" != "$MD5_CHECK" ]
then
  echo "MD5 for $JAVA_PKG does not match! Download again!"
  exit
fi

#
# Validate FMW Package
echo "====================="

if [ ! -e $FMW_PKG ]
then
  echo "Download the Coherence 12c Standalone installer and"
  echo "drop the file $FMW_PKG in this folder before"
  echo "building this Coherence Docker image!"
  exit 
fi

MD5="$FMW_PKG_MD5  $FMW_PKG"
MD5_CHECK="`md5sum $FMW_PKG`"

if [ "$MD5" != "$MD5_CHECK" ]
then
  echo "MD5 for $FMW_PKG does not match! Download again!"
  exit
fi

echo "====================="

docker build -t $DOCKER_IMAGE_NAME .

echo ""
echo "Coherence Docker Container is ready to be used. To start, run 'dockCacheServer.sh -h'"

