#!/bin/bash
#
#Copyright (c) 2020, Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [ "$MANAGED_SERVER_CONTAINER" = "true" ] ; then
   echo "http://{localhost:$MANAGEDSERVER_PORT}/weblogic/ready" ; 
elif [ "$ADMINISTRATION_PORT_ENABLED" = "true" ] ; then 
   echo "https://{localhost:$ADMINISTRATION_PORT}/weblogic/ready" ; 
else 
   echo "http://{localhost:$ADMIN_LISTEN_PORT}/weblogic/ready" ;
fi

