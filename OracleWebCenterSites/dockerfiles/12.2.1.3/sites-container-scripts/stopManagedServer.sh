#!/bin/bash
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This script is used to stop Managed Server.
#
export DOMAIN_NAME=$DOMAIN_NAME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"

. $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

usage()
{
        echo "You must have a value for SERVER_NAME as the first parameter on the command-line."
        echo "Usage: $1 {SERVER_NAME}"
        echo "for example:"
        echo "$1 managedserver1"
}

if [ "$1" = "" ] ; then
        usage $0
        exit
else
        SERVER_NAME="$1"
        shift
fi

export SERVER_NAME=$SERVER_NAME

# Stop Managed server
cd $DOMAIN_HOME/bin

if grep -q "RUNNING" $DOMAIN_HOME/bin/$SERVER_NAME.out
then
    ./stopManagedWebLogic.sh $SERVER_NAME t3://$WCSITES_ADMIN_HOSTNAME:$WCSITES_ADMIN_PORT
    echo "$SERVER_NAME stopped successfully."
    rm -f $DOMAIN_HOME/$SERVER_NAME.out
    rm -f $DOMAIN_HOME/servers/$SERVER_NAME/tmp/$SERVER_NAME.lok
else
    echo "$SERVER_NAME is not RUNNING"
fi
