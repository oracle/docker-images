#! /bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the domain in volume sample"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

admin_host() {
   adminhost=${CUSTOM_ADMIN_HOST:-"InfraAdminContainer"}
   echo Admin server host: ${adminhost}
}

admin_port() {
   adminport=${CUSTOM_ADMIN_PORT:-7001}
   echo Admin server port: ${adminport}
}

set_context
. ${scriptDir}/container-scripts/setRuntimeEnv.sh ${scriptDir}/properties/domain.properties 
admin_host
admin_port

echo "docker run -d -p 9001:${adminport}  --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties 12213-fmw-domain-in-image"

docker run -d -p 9001:${adminport}  --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties 12213-fmw-domain-in-image
