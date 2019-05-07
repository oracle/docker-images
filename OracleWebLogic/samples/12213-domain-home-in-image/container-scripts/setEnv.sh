#!/bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

BUILD_ARG=''
if [ "$#" -eq  "0" ]
   then
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
      export $env_arg
   fi
}

set_env_arg(){
  extract_env $1 $2
  if [ -n "$env_arg" ]; then
      BUILD_ARG="$BUILD_ARG --build-arg $env_arg"
  fi
}

# Set DOMAIN_NAME
set_env_arg DOMAIN_NAME ${PROPERTIES_FILE}

# Set ADMIN_NAME
set_env_arg ADMIN_NAME ${PROPERTIES_FILE}

# Set ADMIN_HOST
set_env_arg ADMIN_HOST ${PROPERTIES_FILE}

# Set ADMIN_PORT
set_env_arg ADMIN_LISTEN_PORT ${PROPERTIES_FILE}

# Set MANAGED_SERVER_PORT
set_env_arg MANAGEDSERVER_PORT ${PROPERTIES_FILE}

# Set DEBUG_PORT
set_env_arg DEBUG_PORT ${PROPERTIES_FILE}

# Set TAG_NAME
set_env_arg TAG_NAME ${PROPERTIES_FILE}

# Set CLUSTER_NAME
set_env_arg CLUSTER_NAME ${PROPERTIES_FILE}

export BUILD_ARG=$BUILD_ARG
echo BUILD_ARG=$BUILD_ARG
