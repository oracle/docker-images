#!/bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


BUILD_ARG=''
if [ "$#" -eq  "0" ]; then
    echo "A properties file with variable definitions should be supplied."
    exit 1
 else
    PROPERTIES_FILE=$1
    echo Export environment variables from the ${PROPERTIES_FILE} property file
fi

extract_env() {
   env_value=`awk '{print $1}' $2 | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo "CUSTOM_$1=$env_value"`
      echo " env_arg: $env_arg"
      export $env_arg
   fi
}

# Set ADMIN_HOST
extract_env ADMIN_HOST ${PROPERTIES_FILE}

# Set ADMIN_PORT
extract_env ADMIN_PORT ${PROPERTIES_FILE}

# Set MANAGEDSERVER_PORT
extract_env MANAGEDSERVER_PORT ${PROPERTIES_FILE}

