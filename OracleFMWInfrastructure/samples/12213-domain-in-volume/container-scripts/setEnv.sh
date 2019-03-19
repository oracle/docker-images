#!/bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


ENV_ARG=''
if [ "$#" -eq  "0" ]
   then
    echo "A properties file with variable definitions should be supplied."
    exit 1
 else
    PROPERTIES_FILE=$1
    echo Export environment variables from the ${PROPERTIES_FILE} properties file
 fi

extract_env() {
   env_value=`awk '{print $1}' $PROPERTIES_FILE | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo "CUSTOM_$1=$env_value"`
      export $env_arg
      echo $env_arg
      ENV_ARG="$ENV_ARG -e $env_arg"
   fi
}

# Set DOMAIN_NAME
extract_env DOMAIN_NAME

# Set ADMIN_NAME
extract_env ADMIN_NAME

# Set ADMIN_HOST
extract_env ADMIN_HOST

# Set ADMIN_LISTEN_PORT
extract_env ADMIN_LISTEN_PORT

# Set MANAGEDSERVER_PORT
extract_env MANAGEDSERVER_PORT

# Set MANAGED_BASE_NAME
extract_env MANAGED_BASE_NAME

# Set MANAGED_SERVER_COUNT
extract_env MANAGED_SERVER_COUNT

# Set CLUSTER_NAME
extract_env CLUSTER_NAME

# Set ADMINISTRATION_PORT_ENABLED
extract_env ADMINISTRATION_PORT_ENABLED

# Set ADMINISTRATION_PORT
extract_env ADMINISTRATION_PORT

# Set RCUPREFIX
extract_env RCUPREFIX

# Set PRODUCTION_MODE
extract_env PRODUCTION_MODE

# Set CUSTOM_DEBUG_PORT
extract_env DEBUG_PORT

# Set CUSTOM_DEBUG_FLAG
extract_env DEBUG_FLAG

# Set JAVA_OPTIONS
extract_env JAVA_OPTIONS

export ENV_ARG=$ENV_ARG
echo ENV_ARG=$ENV_ARG

