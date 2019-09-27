#!/bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


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
   env_value=`awk '{print}' $PROPERTIES_FILE | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo $1=$env_value`
      echo " env_arg: $env_arg"
      export $env_arg
   fi
}

set_env_arg(){
  extract_env $1
  if [ -n "$env_arg" ]; then
      ENV_ARG="$ENV_ARG -e $env_arg"
  fi
}
   

# Set DOMAIN_NAME
set_env_arg DOMAIN_NAME

# Set ADMIN_NAME
set_env_arg ADMIN_NAME

# Set ADMIN_HOST
set_env_arg ADMIN_HOST

# Set ADMIN_LISTEN_PORT
set_env_arg ADMIN_LISTEN_PORT

# Set MANAGEDSERVER_PORT
set_env_arg MANAGEDSERVER_PORT

# Set MANAGED_NAME
set_env_arg MANAGED_NAME
 
# Set ADMINISTRATION_PORT_ENABLED
set_env_arg ADMINISTRATION_PORT_ENABLED

# Set ADMINISTRATION_PORT
set_env_arg ADMINISTRATION_PORT

# Set RCUPREFIX
set_env_arg RCUPREFIX

# Set PRODUCTION_MODE
set_env_arg PRODUCTION_MODE

# Set CONNECTION_STRING
set_env_arg CONNECTION_STRING

# Set DOMAIN_HOST_VOLUME
extract_env DOMAIN_HOST_VOLUME

export ENV_ARG=$ENV_ARG
echo ENV_ARG=$ENV_ARG

