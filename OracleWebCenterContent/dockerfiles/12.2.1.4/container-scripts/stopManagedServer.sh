#!/bin/sh
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
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

echo "hostname=${hostname}"
echo "adminport=${adminport}"

# Stop Managed server
echo ""
echo ""
echo "===================================="
echo "Stoping Managed Server : $server"
echo "===================================="
echo ""
echo ""

# Stop Managed server
cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
WCC_START_LOGFILE="${CONTAINERCONFIG_LOG_DIR}/${server}_start-$(sed 's/-.*//' <<< $hostname).log"

if grep -q "RUNNING" $WCC_START_LOGFILE
then
    ./stopManagedWebLogic.sh $server t3://$adminhostname:$adminport
    
    echo ""
    echo "$server stopped successfully."
    echo ""
    
    rm -f $WCC_START_LOGFILE
    rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/tmp/$server.lok
else
    echo "$server server is not RUNNING...$server server will not Stop"
fi

