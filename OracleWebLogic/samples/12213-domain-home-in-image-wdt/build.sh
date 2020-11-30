#!/bin/sh
#
#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Run the docker build to create the domain home image using the sample model file 
#  simple-topology.yaml, the variable file properties/docker-build/domain.properties and
#  the archive file archive.zip. 
#
# You can use this script to build a domain home using your own model, variable and archive file
#   with a few minor adjustments. Use the provided environment variables and comment out any
#   unnecessary steps to customize for your domain home. 
#
#   Please refer to the README before customizing the build.
#
#  The steps run by this script are as follows:
#
#   set_up                - prepare the script for the build. This includes copying the 
#                           model, variable and archive file to a temporary directory in
#                           the sample directory. The sample directory is used as the docker
#                           build context. This step builds the sample archive file if the 
#                           sample files are used.
#
#   download_tool         - download the latest weblogic-deploy.zip install if the archive
#                           does not exist in the current location. 
#
#   prepare_build_args    - call container-scripts/setEnv.sh to create a string of build arguments
#                           from the properties in the variable file. These arguments are required
#                           for exposing ports and container ENV variables in the sample Dockerfile.
#
#   build_domain_image    - run the docker build with the sample Dockerfile in the context location.
#
#   clean_and_exit        - perform clean up, such as removing the temporary directory, and exit with
#                           the value stored in $return_code. 
#   
#
# This script will return exit code 1 if a step fails or it will return the exit code from
#   docker build if the build was not successful. Zero is returned if the build was successful
#
#
# This script requires the following environment variables:
#
# JAVA_HOME            - The location of the JDK to use.  The caller must set
#                        this variable to a valid Java 8 (or later) JDK.
#
# This script will use the following environment variables to customize the domain image with your own
#  components. In order for this build.sh and Dockerfile to successfully execute with your customizations,
#  you should continue to run the build.sh from the sample location. The build.sh will copy your custom
#  components - model, variable, archive and Dockerfile - to a temporary directory in the sample location
#  so that the files are accessible in the build context. If your model uses file tokens, copy the files 
#  to the properties/docker-build directory and change the model to reference the files in /u01/oracle/properties.
#
# WDT_VERSION           - If the weblogic deploy install image does not exist in the script location, 
#                         the WDT install image is downloaded from the github repository. The downloaded release
#                         is the current supported version for WebLogic Operator. (see the script constant 
#                         WDT_SUPPORTED_RELEASE) To select a different release, set this environment variable to 
#                         the desired release tag or to 'LATEST' to get the lastest release.
#
# CURL                  - If the "curl" command is not on the shell PATH, use this argument
#                         as <location>/curl. The curl is performed if the weblogic-deploy.zip install
#                         has not been downloaded into the sample directory.
#
# TAG_NAME              - Tag the docker image with this name. This overrides the default of 
#                         12213-domain-home-in-image-wdt:latest. 
#
#                         There are four ways to tag the domain home image using this build script.
#
#                           . Do nothing and the image will be tagged with the default name. 
#                           . Add an IMAGE_TAG variable to the variable file and allow the
#                             setEnv.sh to manage the tag. Overrides the default tag.
#                           . Set the TAG_NAME environment variable. Overrides the default tag.
#                           . Set the ADDITIONAL_BUILD_ARGS to include a tag argument 
#                             (i.e. -t sample-tag). Adds an additional tag to the image.
#
# ADDITIONAL_BUILD_ARGS - Additional arguments to include on the docker build statement, for instance an 
#                         additional tag name or proxy variable build args.
#
# CUSTOM_BUILD_ARG      - Use this variable's value to add build arguments to the image build. If this
#                         variable is set, its value is used to set the BUILD_ARG variable instead
#                         of calling the setEnv.sh script. The BUILD_ARG is used on the docker build  
#                         command in the build_domain_image step. 
#
# CUSTOM_WDT_MODEL      - Override the default model simple-topology.yaml in the build_domain_image step.
#
#                         The model, variable and archive files work together to describe the domain.
#                         Make sure to correctly set each corresponding variable. If the variable
#                         is not set, the default file is used. If the variable is set with an empty
#                         string, the file will not be used on the build.
# 
# CUSTOM_WDT_ARCHIVE    - Override the default archive file archive.zip.  
#                      
# CUSTOM_WDT_VARIABLE   - Override the default variable file properties/docker-build/domain.properties.
#                         Be sure the variable file has the properties that setEnv.sh needs to build
#                         the build args needed by this Dockerfile, or provide the build args in the 
#                         CUSTOM_BUILD_ARG.
#

WDT_SUPPORTED_RELEASE=LATEST

if [ -z "${JAVA_HOME}" ] || [ ! -e "${JAVA_HOME}/bin/jar" ]; then 
   echo "JAVA_HOME must be set to version of a java JDK 1.8 or greater"
   exit 1
fi
echo "JAVA_HOME=${JAVA_HOME}"

# Perform any clean up and exit with the return code in variable rc.
clean_and_exit() {
   return_code=${rc:-1}
   rm -rf ${tempLocation}
   echo "Build exiting with return code $return_code"
   exit $return_code
}

# Perform some simple setup to prime the rest of the build shell. This includes setting the model,
# variable and archive variables to the sample files if the variables not already set.
# Copy the model, variable and archive file to the temporary location ${scriptDir}/wdt-files
# to ensure the files accessible from the current context.
set_up() {

   # determine the context for the Dockerfile commands as the directory where this script is run from
   set_context
   
   # make the temporary location 
   tempDir=wdt-files
   tempLocation=${scriptDir}/${tempDir}
   if [ ! -d ${tempLocation} ]; then 
    mkdir ${tempLocation}
	  chmod -R u+rwx ${tempLocation}
   fi
   
   # if the custom wdt archive is NOT set (file or empty string) then build the sample archive
   if [ "${CUSTOM_WDT_ARCHIVE+true}" != "true" ]; then  
      echo "Build the sample archive file"
      WDT_ARCHIVE=${scriptDir}/archive.zip
      build_archive
	    rc=$?
	    if [ $rc -ne 0 ]; then return_code=$rc; clean_and_exit; fi
   fi
   
   # prime the model and variable file variables. Then copy the files to the temporary 
   # location to ensure the files are within the context
   WDT_MODEL=${CUSTOM_WDT_MODEL-"${scriptDir}/simple-topology.yaml"}
   WDT_VARIABLE=${CUSTOM_WDT_VARIABLE-"${scriptDir}/properties/docker-build/domain.properties"}
   WDT_ARCHIVE=${CUSTOM_WDT_ARCHIVE-"${scriptDir}/archive.zip"}
   echo "WDT_MODEL=[${WDT_MODEL}] WDT_VARIABLE=[$WDT_VARIABLE] WDT_ARCHIVE=[$WDT_ARCHIVE]"

   # model is required. If it does not exist then exit
   if [ ! -f ${WDT_MODEL} ]; then
      echo "The model file ${WDT_MODEL} does not exist"
      clean_and_exit
   fi
   echo "Copy the model file ${WDT_MODEL} to ${tempLocation}"
   cp ${WDT_MODEL} ${tempLocation}
   WDT_MODEL=${tempDir}/${WDT_MODEL##*/}
   
   # if variable file exists, copy it to the temp location
   if [ -n "${WDT_VARIABLE}" ] && [ -f ${WDT_VARIABLE} ]; then
      echo "Copy the variable file ${WDT_VARIABLE} to ${tempLocation}"
      cp ${WDT_VARIABLE} ${tempLocation}
      WDT_VARIABLE=${tempDir}/${WDT_VARIABLE##*/}
   fi

   # if archive file exists, copy it to the temp location
   if [ -n "${WDT_ARCHIVE}" ] && [ -f ${WDT_ARCHIVE} ]; then
      echo "Copy the archive file ${WDT_ARCHIVE} to ${tempLocation}"
      cp ${WDT_ARCHIVE} ${tempLocation}
      WDT_ARCHIVE=${tempDir}/${WDT_ARCHIVE##*/}
   fi   
   
   dockerFile=${CUSTOM_DOCKERFILE-"${scriptDir}/Dockerfile"}
   if [ -z "${dockerFile}" ] || [ ! -f $dockerFile ]; then
      echo "Invalid Dockerfile (${dockerFile}). Dockerfile required"
	    clean_and_exit
   fi
   cp ${dockerFile} ${tempLocation}
   dockerFile=${tempLocation}/${dockerFile##*/}
 
}

# Run the docker build using the arguments from both the BUILD_ARG (created by the setEnv.sh) and
# ADDITIONAL_BUILD_ARGS (user specific)
build_domain_image() {
 
   echo "Build the domain home in image using the weblogic deploy tool and tag the image as ${tagName}"
   echo " "
   # Print out the build statement
   echo "eval docker build \
       $BUILD_ARG \
       $MODEL_ARGS \
       $ADDITIONAL_BUILD_ARGS \
       --force-rm=true \
       --no-cache=true \
       -f ${dockerFile} \
       -t ${tagName} \
       ${scriptDir}"
   echo " "
    
   # Expand the tagName variable before exec the docker build.
   eval docker build \
       $BUILD_ARG \
       $MODEL_ARGS \
       $ADDITIONAL_BUILD_ARGS \
       --force-rm=true \
       --no-cache=true \
       -f ${dockerFile} \
       -t ${tagName} \
       ${scriptDir}
	
   rc=$?
   if [ $rc == 0 ]; then 
      imageId=$(docker inspect ${tagName} -f={{.Id}} 2>/dev/null)
      echo "The docker build for image ${tagName} completed successfully with return_code=${rc}."
      echo "The id for image ${tagName} is ${imageId}"
   else
      echo "The docker build for image ${tagName} failed with return_code=${rc}"
   fi
   return $rc
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

# Build the simple-app war and put the application in an archive file.
# The archive is required by the simple-topology.yaml model file
# The build will only warn and not fail if cannot build the war and archive file
build_archive() {
   if [ ! -e "${WDT_ARCHIVE}" ]; then 
      if [ -f "${scriptDir}/build-archive.sh" ]; then
         . "${scriptDir}/build-archive.sh"
         rc=$?
      else
         rc=1
      fi
      if [ $rc != 0 ]; then
         return_code=$rc
         echo "Unable to build the application and archive file required for the sample domain"
         echo "   build-archive.sh return_code=${return_code}"
      fi
   fi
}

# If the weblogic deploy tool install archive file is not found in the Context directory
# download the archive using the CURL command fromthe github.com weblogic-deploy-tooling repository.
download_tool() {
    if [ ! -s "${scriptDir}/weblogic-deploy.zip" ]; then

      # Find the curl command or use the command from the CURL variable
      if [ -z "$CURL" ]; then CURL=`which curl`; fi 
	    if [ -z "$CURL" ] || [ ! -e ${CURL} ]; then curl_failed; fi 
      
      download_url=$(wdturl)
      if [ -z "${download_url}" ]; then curl_failed; fi
      
      echo "Downloading the weblogic deploy tool install: ${download_url}/weblogic-deploy.zip"      
      ${CURL} -m 60 -Lo ${scriptDir}/weblogic-deploy.zip ${download_url}/weblogic-deploy.zip
      rc=$?
      if [ $rc != 0 ]; then echo "${CURL} failed with return code=${rc}"; return_code=$rc; curl_failed; fi
      ${JAVA_HOME}/bin/jar tf ${scriptDir}/weblogic-deploy.zip &> /dev/null
      rc=$?
      if [ $rc != 0 ]; then 
         if [ -f ${scriptDir}/weblogic-deploy.zip ]; then rm ${scriptDir}/weblogic-deploy.zip; fi
         curl_failed
      fi
    else
      echo 'Weblogic deploy tool already in the script directory. Bypass download'	
    fi  
    echo WDT Tool: `ls -l ${scriptDir}/weblogic-deploy.zip`	
}

# This calls the setEnv.sh in container-scripts to parse the ADMIN_HOST, ADMIN_PORT,
# MS_PORT, and DOMAIN_NAME from the sample properties file and pass
# as a string of --build-arg in the variable BUILD_ARG
# If the CUSTOM_BUILD_ARG variable is set, use its value in place of the setEnv.sh
prepare_build_args() {
   BUILD_ARG=
   if [ -n "${CUSTOM_BUILD_ARG}" ]; then
      echo "Using custom build argument string instead of parsing the sample properties file"
      BUILD_ARG=${CUSTOM_BUILD_ARG}
   else
      echo "Create the BUILD_ARG string from the variable file ${WDT_VARIABLE}"
       if [ ! -f ${scriptDir}/${WDT_VARIABLE} ] || \
          [ ! -f ${scriptDir}/container-scripts/setEnv.sh ]; then
          echo "Cannot set the docker build argument string from the variable file ${WDT_VARIABLE}"
          clean_and_exit
      fi
      . ${scriptDir}/container-scripts/setEnv.sh ${scriptDir}/${WDT_VARIABLE}
      rc=$?
      if [ $rc != 0 ]; then
         echo "Failure deriving the docker build-argument string from the variable file ${WDT_VARIABLE}"
         echo "   BUILD_ARG=${BUILD_ARG}"
         echo "   setEnv.sh return_code=${rc}"
         return_code=${rc}
         clean_and_exit
      fi 
   fi
   MODEL_ARGS="--build-arg WDT_MODEL=${WDT_MODEL}"
   if [ -n "${WDT_VARIABLE}" ]; then MODEL_ARGS="${MODEL_ARGS} --build-arg WDT_VARIABLE=${WDT_VARIABLE}"; fi
   if [ -n "${WDT_ARCHIVE}" ]; then MODEL_ARGS="${MODEL_ARGS} --build-arg WDT_ARCHIVE=${WDT_ARCHIVE}"; fi
}

# Determine the tag name for the resulting image using the value in the TAG_NAME.
# The setEnv.sh will set the TAG_NAME variable if the property is found in the
# properties file. This function should be called after the setEnv.sh is run
tag_name() {
   tagName=${TAG_NAME:-"12213-domain-home-in-image-wdt:latest"}
   #echo ${TAG_NAME} and ${tagName}
}

curl_failed() {
      echo "Unable to download the weblogic deploy install using curl from location ${download_url}"
      echo "Manually download the install image weblogic.deploy.zip into location ${scriptDir} and re-run"
      clean_and_exit
}

function wdturl {
  githubRepo=oracle/weblogic-deploy-tooling
  githubRelease=$(if [ -n "$WDT_VERSION" ]; then echo ${WDT_VERSION}; else echo ${WDT_SUPPORTED_RELEASE}; fi)
  if [ "LATEST" != "${githubRelease}" ]; then githubRelease=weblogic-deploy-tooling-${githubRelease#weblogic-deploy-tooling-}; fi
  url=$(github_url $githubRepo $githubRelease)
  rc=$?
  echo $url
  return $rc
}

function github_url {
  if [ $# -eq 2 ]; then 
    var1=$1
    var2=$2
    if [ "$var2" == "LATEST" ]; then release=$(latest_release $var1); else release=$var2; fi
    if [ -n "${release}" ]; then echo "https://github.com/${var1}/releases/download/${release}"; return 0; fi
  fi
  echo ""
  return 1
}
  
function latest_release {
    ${CURL} -m 20 --silent "https://api.github.com/repos/${1}/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

set_up
download_tool
prepare_build_args
tag_name
build_domain_image
return_code=$?
clean_and_exit
