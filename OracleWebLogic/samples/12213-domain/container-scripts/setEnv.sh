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
    RCU_PROPERTIES_FILE=$2
    echo Export environment variables from the ${PROPERTIES_FILE} and ${RCU_PROPERTIES_FILE} properties file
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
      ENV_ARG="$ENV_ARG -e $env_arg"
  fi
}

# Set DOMAIN_NAME
set_env_arg DOMAIN_NAME ${PROPERTIES_FILE}

# Set ADMIN_NAME
set_env_arg ADMIN_NAME ${PROPERTIES_FILE}

# Set ADMIN_PORT
set_env_arg ADMIN_PORT ${PROPERTIES_FILE}

# Set ADMIN_HOST
set_env_arg ADMIN_HOST ${PROPERTIES_FILE}

# Set ADMIN_LISTEN_PORT
set_env_arg ADMIN_LISTEN_PORT ${PROPERTIES_FILE}

# Set MANAGED_SERVER_PORT
set_env_arg MANAGED_SERVER_PORT ${PROPERTIES_FILE}

# Set MANAGED_SERVER_NAME_BASE
set_env_arg MANAGED_SERVER_NAME_BASE ${PROPERTIES_FILE}

# Set CONFIGURED_MANAGED_SERVER_COUNT
set_env_arg CONFIGURED_MANAGED_SERVER_COUNT ${PROPERTIES_FILE}

# Set CLUSTER_NAME
set_env_arg CLUSTER_NAME ${PROPERTIES_FILE}

# Set CLUSTER_TYPE
set_env_arg CLUSTER_TYPE ${PROPERTIES_FILE}

# Set PRODUCTION_MODE_ENABLED
set_env_arg PRODUCTION_MODE_ENABLED ${PROPERTIES_FILE}

# Set DOMAIN_HOST_VOLUME
extract_env DOMAIN_HOST_VOLUME ${PROPERTIES_FILE}

export ENV_ARG=$ENV_ARG
#echo ENV_ARG=$ENV_ARG

