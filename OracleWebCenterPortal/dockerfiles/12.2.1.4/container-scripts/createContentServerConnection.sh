#!/bin/bash
# Copyright (c)  2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
export vol_name=u01
export server=WC_Portal

/$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/createContentServerConnection.py

/$vol_name/oracle/container-scripts/stopManagedServer.sh $server 
rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/$server/tmp/$server.lok
rm -f /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/$server.out

/$vol_name/oracle/container-scripts/startManagedServer.sh $server
