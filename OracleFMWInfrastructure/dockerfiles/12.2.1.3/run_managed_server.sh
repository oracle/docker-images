#! /bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


admin_host() {
   adminhost=${ADMIN_HOST:-"InfraAdfminContainer"}
}

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
docker run -d -p 9802:8002 --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --name InfraManagedContainer oracle/fmw-infrastructure:12.2.1.3 startManagedServer.sh 
