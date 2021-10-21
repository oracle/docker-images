#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#*************************************************************************
# script is used to stop a WebLogic Admin server.
#*************************************************************************
export vol_name=u01
export admin_name=$admin_name
export hostname=`hostname -I`

# Stop Admin server
ADMIN_START_LOGFILE="${CONTAINERCONFIG_LOG_DIR}/AdminServer_start-$(sed 's/-.*//' <<< $hostname).log"
cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
if grep -q "RUNNING" $ADMIN_START_LOGFILE 
then
    ./stopWebLogic.sh
    rm -f $ADMIN_START_LOGFILE
fi
sleep 5
rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/tmp/AdminServer.lok

echo "Admin Server is stopped successfully."
