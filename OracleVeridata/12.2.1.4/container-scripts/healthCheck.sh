#!/bin/bash
#
#Copyright (c) 2021, Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


if [ "$VERIDATA_ADMIN_SERVER" = "true" ] ; then
   echo "curl -k -s --fail http://{localhost:$ADMIN_PORT}/weblogic/ready || exit 1" ;
elif [ "$VERIDATA_MANAGED_SERVER" = "true" ] ; then
   echo "curl -k -s --fail https://{localhost:$VERIDATA_PORT}/weblogic/ready || exit 1" ;
elif [ "$VERIDATA_AGENT" = "true" ] ; then
   echo "exit 0" ;
else
   echo "exit 1" ;
fi
