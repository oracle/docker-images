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

DOMAIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^DOMAIN_NAME= | cut -d "=" -f2`
if [ -n "$DOMAIN_NAME" ]; then
     export DOMAIN_NAME=$DOMAIN_NAME
     echo DOMAIN_NAME=$DOMAIN_NAME
     ENV_ARG="$ENV_ARG -e DOMAIN_NAME=$DOMAIN_NAME"
fi

ADMIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_NAME= | cut -d "=" -f2`
if [ -n "$ADMIN_NAME" ]; then
     export ADMIN_NAME=$ADMIN_NAME
     echo ADMIN_NAME=$ADMIN_NAME
     ENV_ARG="$ENV_ARG -e ADMIN_NAME=$ADMIN_NAME"
fi

ADMIN_HOST=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_HOST= | cut -d "=" -f2`
if [ -n "$ADMIN_HOST" ]; then
    export ADMIN_HOST=$ADMIN_HOST
    echo ADMIN_HOST=$ADMIN_HOST
    ENV_ARG="$ENV_ARG -e ADMIN_HOST=$ADMIN_HOST"
fi

ADMIN_LISTEN_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_LISTEN_PORT= | cut -d "=" -f2`
if [ -n "$ADMIN_LISTEN_PORT" ]; then
    export ADMIN_LISTEN_PORT=$ADMIN_LISTEN_PORT
    echo ADMIN_LISTEN_PORT=$ADMIN_LISTEN_PORT
    ENV_ARG="$ENV_ARG -e ADMIN_LISTEN_PORT=$ADMIN_LISTEN_PORT"
fi

MANAGEDSERVER_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^MANAGEDSERVER_PORT= | cut -d "=" -f2`
if [ -n "$MANAGEDSERVER_PORT" ]; then
    export MANAGEDSERVER_PORT=$MANAGEDSERVER_PORT
    echo MANAGEDSERVER_PORT=$MANAGEDSERVER_PORT
    ENV_ARG="$ENV_ARG -e MANAGEDSERVER_PORT=$MANAGEDSERVER_PORT"
fi

MANAGED_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^MANAGED_NAME= | cut -d "=" -f2`
if [ -n "$MANAGED_NAME" ]; then
    export MANAGED_NAME=$MANAGED_NAME
    echo MANAGED_NAME=$MANAGED_NAME
    ENV_ARG="$ENV_ARG -e MANAGED_NAME=$MANAGED_NAME"
fi

ADMINISTRATION_PORT_ENABLED=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMINISTRATION_PORT_ENABLED= | cut -d "=" -f2`
if [ -n "$ADMINISTRATION_PORT_ENABLED" ]; then
    export ADMINISTRATION_PORT_ENABLED=$ADMINISTRATION_PORT_ENABLED
    echo ADMINISTRATION_PORT_ENABLED=$ADMINISTRATION_PORT_ENABLED
    ENV_ARG="$ENV_ARG -e ADMINISTRATION_PORT_ENABLED=$ADMINISTRATION_PORT_ENABLED"
fi

ADMINISTRATION_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMINISTRATION_PORT= | cut -d "=" -f2`
if [ -n "$ADMINISTRATION_PORT" ]; then
    export ADMINISTRATION_PORT=$ADMINISTRATION_PORT
    echo ADMINISTRATION_PORT=$ADMINISTRATION_PORT
    ENV_ARG="$ENV_ARG -e ADMINISTRATION_PORT=$ADMINISTRATION_PORT"
fi

RCUPREFIX=`awk '{print $1}' $PROPERTIES_FILE | grep ^RCUPREFIX= | cut -d "=" -f2`
if [ -n "$RCUPREFIX" ]; then
    export RCUPREFIX=$RCUPREFIX
    echo RCUPREFIX=$RCUPREFIX
    ENV_ARG="$ENV_ARG -e RCUPREFIX=$RCUPREFIX"
fi

PRODUCTION_MODE=`awk '{print $1}' $PROPERTIES_FILE | grep ^PRODUCTION_MODE= | cut -d "=" -f2`
if [ -n "$PRODUCTION_MODE" ]; then
    export PRODUCTION_MODE=$PRODUCTION_MODE
    echo PRODUCTION_MODE=$PRODUCTION_MODE
    ENV_ARG="$ENV_ARG -e PRODUCTION_MODE=$PRODUCTION_MODE"
fi

export ENV_ARG=$ENV_ARG
echo ENV_ARG=$ENV_ARG

