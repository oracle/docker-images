#! /bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

admin_host() {
   adminhost=${ADMIN_HOST:-"InfraAdminContainer"}
}

#Host volume path where the domain configuration will be persisted
hostvolume="/u01/myhost/temp"

set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the domain home in image sample"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

set_context
. ${scriptDir}/properties/setEnv.sh
echo "Admin Host is: ${ADMIN_HOST}" 
echo "ENV_ARG is: ${ENV_ARG}"

admin_host
docker run -d -p 9001:7001 --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties -v ${hostvolume}:/u01/oracle/user_projects/domains ${ENV_ARG} oracle/fmw-infrastructure:12.2.1.3

