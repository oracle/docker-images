#!/bin/bash

# Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
# The Universal Permissive License (UPL), Version 1.0
#
# This example creates the BUILD_ARG environment variable as a string of --build-arg for 
# the arguments passed on the docker build command. The variable file that is used for the WDT
# create domain step is the input to this script. This insures that the values persisted
# as environment variables in the docker image match the configured domain home.

BUILD_ARG=''
if [ "$#" -eq  "0" ]; then
    echo "A properties file with variable definitions should be supplied."
    exit 1
 else
    PROPERTIES_FILE=$1
    echo Export environment variables from the ${PROPERTIES_FILE} properties file
fi

extract_env() {
   env_value=`awk '{print $1}' $2 | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo "CUSTOM_$1=$env_value"`
      echo " env_arg: $env_arg"
      export $1
   fi
}

set_env_arg(){
  extract_env $1 $2
  if [ -n "$env_arg" ]; then
      BUILD_ARG="$BUILD_ARG --build-arg $env_arg"
  fi
}

DOMAIN_DIR=`awk '{print $1}' $PROPERTIES_FILE | grep ^DOMAIN_NAME= | cut -d "=" -f2`
if [ ! -n "$DOMAIN_DIR" ]; then  
   if [ -n "$DOMAIN_NAME" ]; then
      DOMAIN_DIR=$DOMAIN_NAME
   fi
fi
if [ -n "$DOMAIN_DIR" ]; then
     DOMAIN_NAME=$DOMAIN_DIR
     export DOMAIN_NAME
     echo DOMAIN_NAME=$DOMAIN_NAME
     BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_DOMAIN_NAME=$DOMAIN_NAME"
fi


# Set ADMIN_HOST
set_env_arg ADMIN_HOST ${PROPERTIES_FILE}

# Set ADMIN_SERVER_NAME
set_env_arg ADMIN_SERVER_NAME ${PROPERTIES_FILE}

# Set ADMIN_SERVER_PORT
set_env_arg ADMIN_SERVER_PORT ${PROPERTIES_FILE}

# Set ADMIN_SERVER_SSL_PORT
set_env_arg ADMIN_SERVER_SSL_PORT ${PROPERTIES_FILE}

# Set MANAGED_SERVER_NAME
set_env_arg MANAGED_SERVER_NAME_BASE ${PROPERTIES_FILE}

# Set MANAGED_SERVER_PORT
set_env_arg MANAGED_SERVER_PORT ${PROPERTIES_FILE}

# Set MANAGED_SERVER_SSL_PORT
set_env_arg MANAGED_SERVER_SSL_PORT ${PROPERTIES_FILE}

# Set DEBUG_PORT
set_env_arg DEBUG_PORT ${PROPERTIES_FILE}

# Set SSL_ENABLED
set_env_arg SSL_ENABLED ${PROPERTIES_FILE}

CUSTOM_TAG_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^IMAGE_TAG= | cut -d "=" -f2`
if [ -n "$CUSTOM_TAG_NAME" ]; then
    TAG_NAME=${CUSTOM_TAG_NAME}
    export TAG_NAME
    echo "Set the image tag name to $TAG_NAME"
fi

echo BUILD_ARG=$BUILD_ARG
