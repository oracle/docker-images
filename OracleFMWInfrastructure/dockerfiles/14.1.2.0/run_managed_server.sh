#! /bin/bash
#
#Copyright (c) 2025, Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Pass in the managed server name to run and the mapped port

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

admin_host() {
   adminhost=${ADMIN_HOST:-"InfraAdminContainer"}
   echo "adminhost= ${adminhost}"
}

managed_name() {
   managedname=${MANAGED_NAME:-"infraServer1"}
   echo "managedname= ${managedname}"
}

admin_host
managed_name
ENV_ARG="${ENV_ARG} -e MANAGED_NAME=$managedname -e MANAGED_SERVER_CONTAINER=true"

echo "docker run -d -p 9802:8002 --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --name ${managedname}  oracle/fmw-infrastructure:12.2.1.3 startManagedServer.sh"

docker run -d -p 9802:8002 --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --name ${managedname}  oracle/fmw-infrastructure:12.2.1.3 startManagedServer.sh
