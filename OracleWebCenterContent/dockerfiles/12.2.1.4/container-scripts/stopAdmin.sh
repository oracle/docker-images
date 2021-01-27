#!/bin/sh
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
#*************************************************************************
# script is used to stop a WebLogic Admin server.
#*************************************************************************

export vol_name=u01
export admin_name=$admin_name

# Stop Admin server
cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
if grep -q "RUNNING" /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/weblogic.out
then
    ./stopWebLogic.sh
    rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/weblogic.out
fi
sleep 5
rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/tmp/AdminServer.lok

echo "Servers are stopped successfully."
