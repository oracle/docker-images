#!/bin/bash ex

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
    echo Source environment variables from ${PROPERTIES_FILE} 
fi

# Export any variables that are used by the build.sh into the environment
# If the CUSTOM_VARIABLE_FILE is in the properties file, then the build arg string 
# will be built from this file instead of the file on this script command line
CUSTOM_WDT_VARIABLE=`awk '{print $1}' $PROPERTIES_FILE | grep ^CUSTOM_WDT_VARIABLE= | cut -d "=" -f2`
if [ -n "$CUSTOM_WDT_VARIABLE" ]; then
    export CUSTOM_WDT_VARIABLE
    echo "CUSTOM_WDT_VARIABLE=$CUSTOM_WDT_VARIABLE"
fi

JAVA_HOME=`awk '{print $1}' $PROPERTIES_FILE | grep ^JAVA_HOME= | cut -d "=" -f2`
if [ -n "$JAVA_HOME" ]; then
    export JAVA_HOME
    echo "JAVA_HOME=$JAVA_HOME"
fi

WDT_VERSION=`awk '{print $1}' $PROPERTIES_FILE | grep ^WDT_VERSION= | cut -d "=" -f2`
if [ -n "$WDT_VERSION" ]; then
    export WDT_VERSION
    echo "WDT_VERSION=$WDT_VERSION"
fi


CUSTOM_TAG_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^CUSTOM_TAG_NAME= | cut -d "=" -f2`
if [ -z "$CUSTOM_TAG_NAME" ]; then 
   CUSTOM_TAG_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^IMAGE_TAG= | cut -d "=" -f2`
fi 
if [ -n "$CUSTOM_TAG_NAME" ]; then
    export CUSTOM_TAG_NAME
    echo "CUSTOM_TAG_NAME=$CUSTOM_TAG_NAME"
fi

CUSTOM_WDT_MODEL=`awk '{print $1}' $PROPERTIES_FILE | grep ^CUSTOM_WDT_MODEL= | cut -d "=" -f2`
if [ -n "$CUSTOM_WDT_MODEL" ]; then
    export CUSTOM_WDT_MODEL
    echo "CUSTOM_WDT_MODEL=$CUSTOM_WDT_MODEL"
fi

CUSTOM_WDT_ARCHIVE=`awk '{print $1}' $PROPERTIES_FILE | grep ^CUSTOM_WDT_ARCHIVE= | cut -d "=" -f2`
if [ -n "$CUSTOM_WDT_ARCHIVE" ]; then
    export CUSTOM_WDT_ARCHIVE
    echo "CUSTOM_WDT_ARCHIVE=$CUSTOM_WDT_ARCHIVE"
fi

ADDITIONAL_BUILD_ARGS=`cat $PROPERTIES_FILE | grep -P "((?<=ADDITIONAL_BUILD_ARGS=[']).*[^']|(?<=ADDITIONAL_BUILD_ARGS=)[^'].*)" -o`
if [ -n "$ADDITIONAL_BUILD_ARGS" ]; then
    export ADDITIONAL_BUILD_ARGS
    echo "ADDITIONAL_BUILD_ARGS=$ADDITIONAL_BUILD_ARGS" 
fi

CURL=`awk '{print $1}' $PROPERTIES_FILE | grep ^CURL= | cut -d "=" -f2`
if [ -n "$CURL" ]; then
    export CURL
    echo "CURL=$CURL"
fi

CUSTOM_DOCKERFILE=`awk '{print $1}' $PROPERTIES_FILE | grep ^CUSTOM_DOCKERFILE= | cut -d "=" -f2`
if [ -n "$CUSTOM_DOCKERFILE" ]; then
    export CUSTOM_DOCKERFILE
    echo "NOTICE: Replacing the sample Dockerfile name with $CUSTOM_DOCKERFILE"
fi

CUSTOM_BUILD_ARG=`cat $PROPERTIES_FILE | grep -P "((?<=CUSTOM_BUILD_ARG=[']).*[^']|(?<=CUSTOM_BUILD_ARG=)[^'].*)" -o`
if [ -n "$CUSTOM_BUILD_ARG" ]; then
    export CUSTOM_BUILD_ARG
    echo "CUSTOM_BUILD_ARG=$CUSTOM_BUILD_ARG"
    exit 0
fi

# Now build the BUILD_ARG string from the properties file

if [ -n "$CUSTOM_WDT_VARIABLE" ]; then
   echo "The BUILD_ARG will built from $CUSTOM_WDT_VARIABLE instead of $PROPERTIES_FILE"
   PROPERTIES_FILE=$CUSTOM_WDT_VARIABLE
fi
echo "Build the BUILD_ARGS string from $PROPERTIES_FILE"

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

ADMIN_HOST=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_HOST= | cut -d "=" -f2`
if [ -n "$ADMIN_HOST" ]; then
    export ADMIN_HOST
    echo ADMIN_HOST=$ADMIN_HOST
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_ADMIN_HOST=$ADMIN_HOST"
fi

ADMIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_NAME= | cut -d "=" -f2`
if [ -n "$ADMIN_NAME" ]; then
    export ADMIN_NAME
    echo ADMIN_NAME=$ADMIN_NAME
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_ADMIN_NAME=$ADMIN_NAME"
fi

ADMIN_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_PORT= | cut -d "=" -f2`
if [ -n "$ADMIN_PORT" ]; then
    export ADMIN_PORT
    echo ADMIN_PORT=$ADMIN_PORT
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_ADMIN_PORT=$ADMIN_PORT"
fi

MANAGED_SERVER_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^MANAGED_SERVER_PORT= | cut -d "=" -f2`
if [ -n "$MANAGED_SERVER_PORT" ]; then
    export MANAGED_SERVER_PORT 
    echo MANAGED_SERVER_PORT=$MANAGED_SERVER_PORT
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_MANAGED_SERVER_PORT=$MANAGED_SERVER_PORT"
fi

DEBUG_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^DEBUG_PORT= | cut -d "=" -f2`
if [ -n "$DEBUG_PORT" ]; then
    export DEBUG_PORT
    echo DEBUG_PORT=$DEBUG_PORT
    BUILD_ARG="$BUILD_ARG --build-arg CUSTOM_DEBUG_PORT=$DEBUG_PORT"
fi
echo BUILD_ARG=$BUILD_ARG
