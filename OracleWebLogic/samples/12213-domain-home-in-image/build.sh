#!/bin/sh
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# TAG_NAME              - Tag the docker image with this name. This overrides the default of 
#                         12213-domain-home-in-imag:latest. 
#
#                         There are three ways to tag the domain home image using this build script.
#
#                           . Do nothing and the image will be tagged with the default name. 
#                           . Add an IMAGE_TAG variable to the properties file and allow the
#                             setEnv.sh to manage the tag. Overrides the default tag.
#                           . Set the TAG_NAME environment variable. Overrides the default tag.
#


# Determine the tag name for the resulting image using the value in the TAG_NAME.
# The setEnv.sh will set the TAG_NAME variable if the property is found in the
# properties file. This function should be called after the setEnv.sh is run
tag_name() {
   tagName=${CUSTOM_IMAGE_TAG:-"12213-domain-home-in-image:latest"}
   echo "CUSTOM_IMAGE_TAG  ${tagName} "
}

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

set_context
. ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/properties/docker-build/domain.properties

tag_name
docker build --force-rm=true --no-cache=true $BUILD_ARG -t  ${tagName}  ${scriptDir}
