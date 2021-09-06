#!/bin/bash
#
#Copyright (c) 2020, 2021 Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [[ "$MANAGED_SERVER" = "soa_server1" ]]
then
   echo "http://$(hostname -i):${SOA_PORT}/weblogic/ready"
elif [ "$MANAGED_SERVER" = "oim_server1" ]
then
   echo "http://$(hostname -i):${OIM_PORT}/weblogic/ready"
else
    echo "http://$(hostname -i):${ADMIN_PORT}/weblogic/ready"
fi
