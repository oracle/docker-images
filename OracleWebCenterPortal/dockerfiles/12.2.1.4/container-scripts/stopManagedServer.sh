#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
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
        server="$1"
        shift
fi

export vol_name=u01
export adminhostname=$ADMIN_SERVER_CONTAINER_NAME
export adminport=$ADMIN_PORT
export server=$server
export hostname=`hostname -I`
export DOMAIN_NAME='wcp-domain'

# Stop Managed server
cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
WCP_START_LOGFILE="${CONTAINERCONFIG_LOG_DIR}/${server}_start-$(sed 's/-.*//' <<< $hostname).log"

if grep -q "RUNNING" $WCP_START_LOGFILE
then
    ./stopManagedWebLogic.sh $server t3://$adminhostname:$adminport
    echo "$server stopped successfully."
    rm -f $WCP_START_LOGFILE
    rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/tmp/$server.lok
else
    echo "$server is not RUNNING"
fi
