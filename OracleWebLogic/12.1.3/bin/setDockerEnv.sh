#!/bin/bash
# 
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to configure the environment to run WebLogic on a Docker container

# WebLogic Version
VERSION="12.1.3"
DEFAULT_IMAGE_NAME="oracle/weblogic:$VERSION"
DEFAULT_DEV_IMAGE_NAME="$DEFAULT_IMAGE_NAME-dev"

# WebLogic Generic Pacakge and MD5
WLS_GENERIC_PKG_NAME="fmw_12.1.3.0.0_wls.jar"
WLS_GENERIC_PKG_MD5="8378fe936b476a6f4ca5efa465a435e3"

# WebLogic Developer Package and MD5
WLS_DEV_PKG_NAME="wls1213_dev.zip"
WLS_DEV_PKG_MD5="0a9152e312997a630ac122ba45581a18"

# Java Package
JAVA_VERSION="8u25"
JAVA_PKG="jdk-${JAVA_VERSION}-linux-x64.rpm"
JAVA_PKG_MD5="6a8897b5d92e5850ef3458aa89a5e9d7"

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
ADMIN_PORT=7001
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

