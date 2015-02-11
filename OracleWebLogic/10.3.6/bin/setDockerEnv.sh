#!/bin/bash
# 
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to configure the environment to run WebLogic on a Docker container

# WebLogic Version
VERSION="10.3.6"
DEFAULT_IMAGE_NAME="oracle/weblogic:$VERSION"
DEFAULT_DEV_IMAGE_NAME="$DEFAULT_IMAGE_NAME-dev"

# WebLogic Generic Pacakge and MD5
WLS_GENERIC_PKG_NAME="wls1036_generic.jar"
WLS_GENERIC_PKG_MD5="33d45745ff0510381de84427a7536f65"

# WebLogic Developer Package and MD5
WLS_DEV_PKG_NAME="wls1036_dev.zip"
WLS_DEV_PKG_MD5="9690c184b81731b8feaa245b0060a296"

# Java Package
JAVA_VERSION="7u75"
JAVA_PKG="jdk-${JAVA_VERSION}-linux-x64.rpm"
JAVA_PKG_MD5="53b8513548ae527d79899902524a06e1"

#########################################
#########################################
#########################################
#                                       #
# DO NOT CHANGE BELOW ###################
#                                       #
#########################################
DISTRIBUTION="generic"
if [ -z "$IMAGE_NAME" ]; then
  IMAGE_NAME="$DEFAULT_IMAGE_NAME"
fi

TIMESTAMP=`date +%s`
NM_CONTAINER_NAME="nodemanager${TIMESTAMP}"
ADMIN_CONTAINER_NAME="wlsadmin"
ATTACH_ADMIN_TO=7001
ATTACH_NM_TO=5556

# WEBLOGIC GENERIC
WLS_PKG=$WLS_GENERIC_PKG_NAME
WLS_PKG_MD5=$WLS_GENERIC_PKG_MD5

# Developer Distribution Setup
setup_developer() {
  IMAGE_NAME="$DEFAULT_DEV_IMAGE_NAME"
  echo "Configuration for developer distribution enabled."
  DISTRIBUTION="developer"
  WLS_PKG=$WLS_DEV_PKG_NAME
  WLS_PKG_MD5=$WLS_DEV_PKG_MD5
}

#
# Function to check MD5 of $1 against expected value $2
#
check_md5() {
  MD5="MD5 ($1) = $2"
  if [[ "`uname`" == 'Darwin' ]]; then
    MD5_CHECK=`md5 "$1"`
  else 
    MD5_CHECK="$(md5sum --tag $1)"
  fi
    
  if [[ "$MD5" == "$MD5_CHECK" ]]; then 
    return 0 
  else
    return 1
  fi
}

