#! /bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


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
hostvolume=/home/username/domain_home
echo "Host volume to write the domain is: $hostvolume"

admin_host() {
   adminhost=${ADMIN_HOST:-"InfraAdminContainer"}
}

echo "Admin Host is: ${ADMIN_HOST}" 
echo "ENV_ARG is: ${ENV_ARG}"

admin_host

echo " docker run -d -p 9001:7001 -p 9002:9002 --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties -v ${hostvolume}:/u01/oracle/user_projects/domains ${ENV_ARG} oracle/fmw-infrastructure:12.2.1.3"

docker run -d -p 9001:7001 -p 9002:9002 --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties -v ${hostvolume}:/u01/oracle/user_projects/domains ${ENV_ARG} oracle/fmw-infrastructure:12.2.1.3

