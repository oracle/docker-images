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
      export $env_arg
      echo $env_arg
      ENV_ARG="$ENV_ARG -e $env_arg"
   fi
}

# Set DOMAIN_NAME
extract_env DOMAIN_NAME ${PROPERTIES_FILE}

# Set ADMIN_NAME
extract_env ADMIN_NAME ${PROPERTIES_FILE}

# Set ADMIN_HOST
extract_env ADMIN_HOST ${PROPERTIES_FILE}

# Set ADMIN_LISTEN_PORT
extract_env ADMIN_LISTEN_PORT ${PROPERTIES_FILE}

# Set MANAGEDSERVER_PORT
extract_env MANAGEDSERVER_PORT ${PROPERTIES_FILE}

# Set MANAGED_BASE_NAME
extract_env MANAGED_BASE_NAME ${PROPERTIES_FILE}

# Set MANAGED_SERVER_COUNT
extract_env MANAGED_SERVER_COUNT ${PROPERTIES_FILE}

# Set CLUSTER_NAME
extract_env CLUSTER_NAME ${PROPERTIES_FILE}

# Set ADMINISTRATION_PORT_ENABLED
extract_env ADMINISTRATION_PORT_ENABLED ${PROPERTIES_FILE}

# Set ADMINISTRATION_PORT
extract_env ADMINISTRATION_PORT ${PROPERTIES_FILE}

# Set PRODUCTION_MODE
extract_env PRODUCTION_MODE ${PROPERTIES_FILE}

# Set CUSTOM_DEBUG_PORT
extract_env DEBUG_PORT ${PROPERTIES_FILE}

# Set CUSTOM_DEBUG_FLAG
extract_env DEBUG_FLAG ${PROPERTIES_FILE}

# Set RCUPREFIX
extract_env RCUPREFIX ${RCU_PROPERTIES_FILE}

# Set CONNECTION_STRING
extract_env CONNECTION_STRING ${RCU_PROPERTIES_FILE}

export ENV_ARG=$ENV_ARG
echo ENV_ARG=$ENV_ARG

