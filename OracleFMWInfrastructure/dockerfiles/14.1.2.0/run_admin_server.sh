#! /bin/bash
#
#Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the OracleFMWInfrastructure image"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

set_context
. ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/properties/domain.properties

# HOST volume where the domain home will be persisted
domain_host_volume() {
   domainhostvol=${DOMAIN_HOST_VOLUME}
   if [ -z "$domainhostvol" ]; then
      echo "The parameter DOMAIN_HOST_VOLUME must be set in ${scriptDir}/properties/domain.properties."
      exit
   else
      if [ ! -d "$domainhostvol" ]; then
         echo "Host volume $domainhostvol is an invalid directory, set DOMAIN_HOST_VOLUME in ${scriptDir}/properties/domain.properties to a valid host directory"
         exit
      fi
   fi
   echo "The domain configuration will get persisted in the host volume: $domainhostvol"
}

admin_host() {
   adminhost=${ADMIN_HOST:-"InfraAdminContainer"}
   echo "Admin Host is: $adminhost"
}

admin_host
domain_host_volume

echo " docker run -d -p 9001:7001 -p 9002:9002 --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties -v ${domainhostvol}:/u01/oracle/user_projects/domains ${ENV_ARG} oracle/fmw-infrastructure:12.2.1.4"

docker run -d -p 9001:7001 -p 9002:9002 --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties -v ${domainhostvol}:/u01/oracle/user_projects/domains ${ENV_ARG} oracle/fmw-infrastructure:12.2.1.4

