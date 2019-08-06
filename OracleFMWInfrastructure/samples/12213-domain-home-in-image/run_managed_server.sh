#! /bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Pass in the managed server name to run and the mapped port
   
if [ "$#" -eq  "0" ]
   then
    echo "The managed server name to be started and the docker port to map to the server ports must be passed in"
    exit 1
 else
    managedname=$1
    mapedport=$2
    echo "The managed server name to be started ${managedname} and the docker port to map to the server port ${mapedport}"
fi


# The location where the script is running will be used as the Context for
# the docker build Dockerfile commands
set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the domain home in image sample"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

managed_name() {
  if [ -z "$managedname" ]; then
     echo "You must pass in the name of the managed server that you want to start"
     exit
  else
     export managedname=$managedname
     echo "Name of managed server to be started is $managedname"
  fi
}

maped_port() {
  if [ -z "$mapedport" ]; then
     echo "You must pass in the docker port that will be mapped to the managed server port $CUSTOM_MANAGED_PORT"
     exit
  else
     export mapedport=$mapedport
     echo "docker port $mapedport will be mapped to managed server port $CUSTOM_MANAGED_PORT"
  fi
}

set_context
. ${scriptDir}/container-scripts/setRuntimeEnv.sh ${scriptDir}/properties/domain.properties 
managed_name
maped_port
ENV_ARG="${ENV_ARG} -e CUSTOM_MANAGED_NAME=$managedname"

echo "docker run -d -p ${mapedport}:${CUSTOM_MANAGEDSERVER_PORT} --network=InfraNET ${ENV_ARG} -v ${scriptDir}/properties:/u01/oracle/properties --name ${managedname} 12213-fmw-domain-in-image startManagedServer.sh" 

docker run -d -p ${mapedport}:${CUSTOM_MANAGEDSERVER_PORT} --network=InfraNET ${ENV_ARG} -v ${scriptDir}/properties:/u01/oracle/properties --name ${managedname} 12213-fmw-domain-in-image startManagedServer.sh 
