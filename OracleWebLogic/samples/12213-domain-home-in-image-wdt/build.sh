#!/bin/sh
#
#Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
if [ ! -d ${JAVA_HOME} ]; then 
   echo "JAVA_HOME must be set to version of a java JDK 1.8 or greater"
   exit 1
fi

scriptDir="$( cd "$( dirname $0 )" && pwd )"

# Build the application and the archive file with the application
. ${scriptDir}/build-archive.sh

# parse the ADMIN_HOST, ADMIN_PORT, MS_PORT, and DOMAIN_NAME from the sample properties file and pass
# as a string of --build-arg in the variable BUILD_ARG

. ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/properties/docker-build/domain.properties

# provide additional arguments on the build command, such as those values needed to perform the curl against the 
# github.com weblogic-deploy-tooling repository, in the environment variable ADDITIONAL_BUILD_ARGS

if [ ! -e ${scriptDir}/weblogic-deploy.zip ]; then
   curl -Lo ${scriptDir}/weblogic-deploy.zip https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.14/weblogic-deploy.zip
fi

if [ ! -e ${scriptDir}/weblogic-deploy.zip ]; then
   echo 'Unable to download the weblogic-deploy-tooling release archive'
   exit
fi 

echo "docker build \
    $BUILD_ARG \
    --build-arg WDT_MODEL=simple-topology.yaml \
    --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
    --build-arg WDT_ARCHIVE=archive.zip \
    --force-rm=true \
    $ADDITIONAL_BUILD_ARGS \
    -f ${scriptDir}/Dockerfile \
    -t 12213-domain-home-in-image-wdt \
    ${scriptDir}"
    
docker build \
    $BUILD_ARG \
    --build-arg WDT_MODEL=simple-topology.yaml \
    --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
    --build-arg WDT_ARCHIVE=archive.zip \
    --force-rm=true \
    $ADDITIONAL_BUILD_ARGS \
    -f ${scriptDir}/Dockerfile \
    -t 12213-domain-home-in-image-wdt \
    ${scriptDir}
