#! /bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Pass in the managed server name to run and the mapped port
export CUSTOM_MANAGED_NAME=$1
export PORT=$2

set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the domain home in volume sample"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

set_context
. ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/properties/domain.properties ${scriptDir}/properties/rcu.properties


echo "Admin Host is: ${adminhost}"
admin_host() {
   adminhost=${CUSTOM_ADMIN_HOST:-"InfraAdminContainer"}
}

managed_name() {
   managedname=${CUSTOM_MANAGED_NAME:-"infraMS1"}
   echo ${managed_name}
}

maped_port() {
   mapedport=${PORT:-9802}
   echo ${mapedport}
}

admin_host
managed_name
maped_port
echo "Admin Host is: ${adminhost}"
ENV_ARG="${ENV_ARG} -e CUSTOM_MANAGED_NAME=$managedname"
#echo "ENV_ARG is: ${ENV_ARG}"

echo "docker run -d -p ${mapedport}:8002 --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --name ${managedname} 12213-fmw-domain-in-volume startFMWManagedServer.sh" 

docker run -d -p ${mapedport}:8002 --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --name ${managedname} 12213-fmw-domain-in-volume startFMWManagedServer.sh 
