#!/bin/bash
#
#Copyright (c) 2020, 2021, Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [ "$MANAGED_SERVER_CONTAINER" = "true" ] ; then
   echo "http://$(hostname -i):${MANAGEDSERVER_PORT}/weblogic/ready" ;
else 
   echo "http://$(hostname -i):7001/weblogic/ready" ;
fi


