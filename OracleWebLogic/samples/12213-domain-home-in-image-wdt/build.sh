#!/bin/sh
#
#Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# This script requires the following environment variables:
#
# JAVA_HOME            - The location of the JDK to use.  The caller must set
#                        this variable to a valid Java 8 (or later) JDK.
#
# This script will use the following environment variables to direct the image build
#
# TAG_NAME              - Tag the docker image with the supplied tag name. This overrides 
#                         the default of 12213-domain-home-in-image-wdt:latest 
#
#
# CUSTOM_BUILD_ARG      - Use this string of build arguments instead of running the setEnv.sh 
#                         to create the build arguments from the sample domain.properties file.
#
# ADDITIONAL_BUILD_ARGS - Additional arguments to include on the docker build statement 
#                         such as an additional tag name or build argument.
#
# CURL                  - If the "curl" command is not on the shell PATH, use this argument to
#                         as <location>/curl. The curl is performed if the weblogic-deploy.zip install
#                         has not been downloaded into the sample directory.
#

if [ -z ${JAVA_HOME} ]; then 
   echo "JAVA_HOME must be set to version of a java JDK 1.8 or greater"
   exit 1
fi
echo JAVA_HOME=${JAVA_HOME}

scriptDir="$( cd "$( dirname $0 )" && pwd )"
if [ ! -d ${scriptDir} ]; then
    echo "Unable to determine the working directory for the domain home in image sample"
    echo "Using shell /bin/sh to determine and found ${scriptDir}"
    exit 1
fi
echo "Context for docker build is ${scriptDir}"

# Build the application and put the application in an archive file.
# The archive is required by the simple-topology.yaml model file
if [ -r ${scriptDir}/build-archive.sh ]; then
   . ${scriptDir}/build-archive.sh
   rc=$?
else
   rc=127
fi
if [ $rc != 0 ]; then
   echo "Unable to build the application and archive file required for the sample domain"
   echo "   this might cause the create domain to fail as it is required by the sample model file"
   echo "   build-archive.sh RC=${rc}"
fi

# provide additional arguments on the build command, such as those values needed to perform the curl against the 
# github.com weblogic-deploy-tooling repository, in the environment variable ADDITIONAL_BUILD_ARGS
 
if [ ! -e "${scriptDir}/weblogic-deploy.zip" ]; then
   echo "Downloading the weblogic deploy tool archive weblogic-deploy.zip from the github repository"
   ( if [ -z $CURL ]; then CURL=`which curl`; fi; if [ -z $CURL ]; then curl_failed; fi )
 
   ${CURL} -Lo ${scriptDir}/weblogic-deploy.zip https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.14/weblogic-deploy.zip
   rc=$?
   if [ $rc != 0 ] || [ ! -e ${scriptDir}/weblogic-deploy-zip ]; then
      echo "${CURL} RC=${rc}"
      curl_failed
   fi
fi 
 
# parse the ADMIN_HOST, ADMIN_PORT, MS_PORT, and DOMAIN_NAME from the sample properties file and pass
# as a string of --build-arg in the variable BUILD_ARG if the CUSTOM_BUILD_ARG is not set
if [ -n "${CUSTOM_BUILD_ARG}" ]; then
   echo "Using custom build argument string instead of parsing the sample properties file"
   BUILD_ARG=${CUSTOM_BUILD_ARG}
else
   if [ ! -r ${scriptDir}/properties/docker-build/domain.properties ] || \
       [ ! -r ${scriptDir}/container-scripts/setEnv.sh ]; then
       echo "Cannot set the docker build argument string from the domain.properties"
       exit 1
   fi
   . ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/properties/docker-build/domain.properties
   rc=$?
   echo setenv=${rc}
   if [ ${rc} != 0 ]; then
      echo "Failure deriving the docker build-argument string from the domain.properties file"
      echo "   BUILD_ARG=${BUILD_ARG}"
      echo "   setEnv.sh RC=${rc}"
      exit ${rc}
   fi 
fi

tagName=${TAG_NAME:-"12213-docker-home-in-image-wdt:latest"}
echo ${TAG_NAME} and ${tagName}
echo "Build the domain home in image using the weblogic deploy tool and tag the image as ${tagName}"
echo " "
echo "eval docker build \
    $BUILD_ARG \
    --build-arg WDT_MODEL=simple-topology.yaml \
    --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
    --build-arg WDT_ARCHIVE=archive.zip \
    --force-rm=true \
    $ADDITIONAL_BUILD_ARGS \
    -f ${scriptDir}/Dockerfile \
    -t ${tagName} \
    ${scriptDir}"
echo " "
    
eval docker build \
    $BUILD_ARG \
    --build-arg WDT_MODEL=simple-topology.yaml \
    --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
    --build-arg WDT_ARCHIVE=archive.zip \
    --force-rm=true \
    $ADDITIONAL_BUILD_ARGS \
    -f ${scriptDir}/Dockerfile \
    -t ${tagName} \
    ${scriptDir}
	
rc=$?
if [ ${rc} == 0 ]; then 
   imageId=$(docker inspect ${tagName} -f={{.Id}} 2>/dev/null)
   echo "The docker build for image ${tagName} completed successfully with rc=${rc}."
   echo "The id for image ${tagName} is ${imageId}"
else
   echo "The docker build for image ${tagName} failed with rc=${rc}"
fi

exit ${rc}

curl_failed() {
      echo "Unable to download the weblogic deploy install using curl"
      echo "Download the install image weblogic.deploy.zip into location ${scriptDir}"
      echo "The weblogic deploy tool archive weblogic-deploy.zip is available at https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.14/weblogic-deploy.zip"
      exit 1
}