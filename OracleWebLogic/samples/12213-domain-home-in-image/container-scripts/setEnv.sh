#!/bin/bash ex

# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
# The Universal Permissive License (UPL), Version 1.0
#
# This example creates the BUILD_ARG environment variable as a string of --build-arg for 
# the arguments passed on the docker build command. The variable file that is used for the WDT
# create domain step is the input to this script. This insures that the values persisted
# as environment variables in the docker image match the configured domain home.

BUILD_ARG=''
if [ $# > 1 ]; then
  PROPERTIES_FILE=$1
fi

if [ ! -e "${PROPERTIES_FILE}" ]; then
    echo "A properties file with variable definitions should be supplied."
fi

echo Export environment variables from the ${PROPERTIES_FILE} properties file

CUSTOM_DOMAIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^DOMAIN_NAME= | cut -d "=" -f2`
if [ -n "$CUSTOM_DOMAIN_NAME" ]; then
     export CUSTOM_DOMAIN_NAME=$CUSTOM_DOMAIN_NAME
     echo CUSTOM_DOMAIN_NAME=$CUSTOM_DOMAIN_NAME
     BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_DOMAIN_NAME=$CUSTOM_DOMAIN_NAME"
fi

CUSTOM_ADMIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_NAME= | cut -d "=" -f2`
if [ -n "$CUSTOM_ADMIN_NAME" ]; then
     export CUSTOM_ADMIN_NAME=$CUSTOM_ADMIN_NAME
     echo CUSTOM_ADMIN_NAME=$CUSTOM_ADMIN_NAME
     BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_ADMIN_NAME=$CUSTOM_ADMIN_NAME"
fi

CUSTOM_ADMIN_HOST=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_HOST= | cut -d "=" -f2`
if [ -n "$CUSTOM_ADMIN_HOST" ]; then
    export CUSTOM_ADMIN_HOST=$CUSTOM_ADMIN_HOST
    echo CUSTOM_ADMIN_HOST=$CUSTOM_ADMIN_HOST
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_ADMIN_HOST=$CUSTOM_ADMIN_HOST"
fi

CUSTOM_ADMIN_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_PORT= | cut -d "=" -f2`
if [ -n "$CUSTOM_ADMIN_PORT" ]; then
    export CUSTOM_ADMIN_PORT=$CUSTOM_ADMIN_PORT
    echo CUSTOM_ADMIN_PORT=$CUSTOM_ADMIN_PORT
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_ADMIN_PORT=$CUSTOM_ADMIN_PORT"
fi

CUSTOM_MS_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^MANAGED_SERVER_PORT= | cut -d "=" -f2`
if [ -n "$CUSTOM_MS_PORT" ]; then
    export CUSTOM_MS_PORT=$CUSTOM_MS_PORT 
    echo CUSTOM_MS_PORT=$CUSTOM_MS_PORT
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_MS_PORT=$CUSTOM_MS_PORT"
fi

CUSTOM_DEBUG_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^DEBUG_PORT= | cut -d "=" -f2`
if [ -n "$CUSTOM_DEBUG_PORT" ]; then
    export CUSTOM_DEBUG_PORT=$CUSTOM_DEBUG_PORT
    echo CUSTOM_DEBUG_PORT=$CUSTOM_DEBUG_PORT
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_DEBUG_PORT=$CUSTOM_DEBUG_PORT"
fi

echo BUILD_ARG=$BUILD_ARG
