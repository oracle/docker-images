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
    echo Export environment variables from the ${PROPERTIES_FILE} and ${RCU_PROPERTIES_FILE} properties file
 fi

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
. ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/properties/domain.properties


echo "Admin Host is: ${adminhost}"
admin_host() {
   adminhost=${CUSTOM_ADMIN_HOST:-"AdminContainer"}
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
     echo "You must pass in the docker port that will be mapped to the managed server port $CUSTOM_MANAGED_SERVER_PORT"
     exit
  else
     export mapedport=$mapedport
     echo "docker port $mapedport will be mapped to managed server port $CUSTOM_MANAGED_SERVER_PORT"
  fi
}

admin_host
managed_name
maped_port
echo "Admin Host is: ${adminhost}"
ENV_ARG="${ENV_ARG} -e CUSTOM_MANAGED_NAME=$managedname"

echo "docker run -d -p ${mapedport}:${CUSTOM_MANAGED_SERVER_PORT} -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --link ${adminhost}:${adminhost} --name ${managedname} 12213-weblogic-domain-in-volume /u01/oracle/container-scripts/startManagedServer.sh" 

docker run -d -p ${mapedport}:${CUSTOM_MANAGED_SERVER_PORT} -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --link ${adminhost}:${adminhost} --name ${managedname} 12213-weblogic-domain-in-volume /u01/oracle/container-scripts/startManagedServer.sh 
