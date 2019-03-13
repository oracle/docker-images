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
#   set_up                - prepare the script for the build. call container-scripts/setEnv.sh to create a 
#                           string of build arguments and source variables into the build.sh environment.
#                           The values in the build args string are required for exposing ports and container
#                           ENV variables in the sample Dockerfile.
#
#                           Copy the model, variable and archive file to a temporary directory in
#                           the sample directory. The sample directory is used as the docker
#                           build context. This step builds the sample archive file if the 
#                           sample files are used.
#
#   download_tool         - download the latest weblogic-deploy.zip install if the archive
#                           does not exist in the current location. 
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
# There are three ways that you can set the environment variables before running build.sh to build the docker image.
#
#  1. Manually set the environment variable:
#     WDT_VERSION=LATEST
#     export WDT_VERSION  
#
#  2. Add the variable directly to the build.sh script. It is suggested you put them under the SCRIPT ENVIRONMENT VARIABLES
#     section below so they are highly visible.
#
#  3. Add the environment variable to the domain.properties or the file in the CUSTOM_WDT_VARIABLE (set by method 1 or 2). 
#     The setEnv.sh will inspect the properties file for known variables and export each one to the environment.
#
# Variables set by method 2 will override variables set by method 1. Variables set by method 3 will override variables set
#  by methods 1 and 2. 
# 
# WDT_VERSION           - If the weblogic deploy install image does not exist in the script location, 
#                         the latest release of the WDT install image is downloaded from the github 
#                         repository. To select a specific release instead, set this environment variable to 
#                         the desired release tag (i.e. 0.20 or weblogic-deploy-tooling-0.20).
#
# CURL                  - If the "curl" command is not on the shell PATH, use this argument
#                         as <location>/curl. The curl is performed if the weblogic-deploy.zip install
#                         has not been downloaded into the sample directory.
#
# CUSTOM_TAG_NAME       - Tag the docker image with this name. This overrides the default of 
#                         12213-domain-home-in-image-wdt:latest. 
#
#                         There are four ways to tag the domain home image using this build script.
#
#                           . Do nothing and the image will be tagged with the default name.
#                           . Add an IMAGE_TAG variable to the properties file (maintains backward compatibility). Overrides 
#                             the default tag.
#                           . Set the CUSTOM_TAG_NAME environment variable. Overrides both the default tag and IMAGE_TAG.        
#                           . Set the ADDITIONAL_BUILD_ARGS to include a tag argument 
#                             (i.e. -t sample-tag). Adds an additional tag to the image.
#
# ADDITIONAL_BUILD_ARGS - Additional arguments to include on the docker build statement, for instance an 
#                         additional tag name or proxy variable build args.
#
# CUSTOM_BUILD_ARG      - Use this variable's value to add build arguments to the image build. If this
#                         variable is set, its value is used to set the BUILD_ARG variable instead
#                         overriding the setEnv.sh script. The BUILD_ARG is used on the docker build  
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
# CUSTOM_DOCKERFILE     - Alternative Dockerfile
#

# SCRIPT ENVIRONMENT VARIABLES
###################


###################


# DEFAULTS
WDT_SUPPORTED_RELEASE=LATEST
WDT_GITHUB_REPO=oracle/weblogic-deploy-tooling

  
# Perform any clean up and exit with the return code 
clean_and_exit() {
   if [ $#  -eq 0 ]; then return_code=1; else return_code=$1; fi
   rm -rf ${tempLocation}
   echo "*** build.sh exiting with return code $return_code"
   exit $return_code
}

# Call the setEnv.sh to create the BUILD_ARG from the properties file and source any variables into the 
# script run environment
set_args() {  
   if [ ! -f ${WDT_VARIABLE} ] ; then
	  echo "Cannot set the docker build argument string from the variable file ${WDT_VARIABLE} using the script ${scriptDir}/container-scripts/setEnv.sh"
	  clean_and_exit
  fi
  . ${scriptDir}/container-scripts/setEnv.sh ${WDT_VARIABLE}
  rc=$?
  if [ $rc != 0 ]; then
	 echo "Failure deriving the docker build-argument string from the variable file ${WDT_VARIABLE}"
	 echo "   BUILD_ARG=${BUILD_ARG}"
	 echo "   setEnv.sh return_code=${rc}"
	 clean_and_exit $rc
  fi 
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
   
    # Source the environment variables from the environment file and properties file.
    # If the CUSTOM_WDT_VARIABLE is sourced in the environment, use this value to locate the properties files.
	# If the properties file contains the 
    WDT_VARIABLE=${CUSTOM_WDT_VARIABLE:-${scriptDir}/properties/docker-build/domain.properties}
	set_args
	WDT_VARIABLE=${CUSTOM_WDT_VARIABLE:-$WDT_VARIABLE}

	if [ -n "${JAVA_HOME}" ]; then
	    if [ -d ${JAVA_HOME} ]; then 
	      if [ -f ${JAVA_HOME}/bin/java ]; then 
		     JAVA=${JAVA_HOME}/bin/java
		  elif	[ -f ${JAVA_HOME}/java ]; then
		     JAVA=${JAVA_HOME}/java
		  fi
		elif [ -f ${JAVA_HOME} ]; then 
           JAVA=${JAVA_HOME} 		
	    fi 
	else
	  JAVA=`which java`
	fi
    JAVA_BIN=${JAVA%/*}
	
	if [ ! -f $JAVA ] || [[ "`${JAVA} -version 2>&1 | grep ' version ' | sed -E 's/.*"([^"]+)".*/\1/'`" < "1.8" ]] || [ ! -f ${JAVA_BIN}/jar ]; then
	   echo "JAVA_HOME must be set to valid location of a java JDK version 1.8 or greater"
	   if [ -n "$JAVA" ]; then echo "$JAVA is version \"`$JAVA -version`\" and jdk jar must exist at location ${JAVA_BIN}"; fi
	   clean_and_exit
    fi

	# if the custom wdt archive is NOT set (file or empty string) then build the sample archive
    if [ "${CUSTOM_WDT_ARCHIVE+true}" != "true" ]; then  
      echo "Build the sample archive file"
      WDT_ARCHIVE=${scriptDir}/archive.zip
      build_archive
	  rc=$?
	  if [ $rc -ne 0 ]; then clean_and_exit $rc; fi
   fi
   
   # prime the model and variable file variables. Then copy the files to the temporary 
   # location to ensure the files are within the context
   WDT_MODEL=${CUSTOM_WDT_MODEL:-${scriptDir}/simple-topology.yaml}
   WDT_ARCHIVE=${CUSTOM_WDT_ARCHIVE:-${scriptDir}/archive.zip}
   
   WDT_MODEL=`eval echo $WDT_MODEL`
   WDT_ARCHIVE=`eval echo $WDT_ARCHIVE`
   WDT_VARIABLE=`eval echo $WDT_VARIABLE`


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
   
   if [ -n "${CUSTOM_BUILD_ARG}" ]; then
     echo "Using custom build argument string instead of the properties file build arg string"
     BUILD_ARG=${CUSTOM_BUILD_ARG}
   fi    		
		
   MODEL_ARGS="--build-arg WDT_MODEL=${WDT_MODEL}"
   if [ -n "${WDT_VARIABLE}" ]; then MODEL_ARGS="${MODEL_ARGS} --build-arg WDT_VARIABLE=${WDT_VARIABLE}"; fi
   if [ -n "${WDT_ARCHIVE}" ]; then MODEL_ARGS="${MODEL_ARGS} --build-arg WDT_ARCHIVE=${WDT_ARCHIVE}"; fi
   
   dockerFile=${CUSTOM_DOCKERFILE:-${scriptDir}/Dockerfile}
   if [ -z "${dockerFile}" ] || [ ! -f $dockerFile ]; then
      echo "Invalid Dockerfile ${dockerFile}. Dockerfile required"
      clean_and_exit
   fi
   cp ${dockerFile} ${tempLocation}
   dockerFile=${tempLocation}/${dockerFile##*/}
     
   tag_name	 
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
      if [ -n "$CURL" ]; then CURL=`eval echo ${CURL}`; else CURL=`which curl`; fi
	  if [ -x $CURL ]; then 
	     download_url=$(wdturl)
	  else 
	     echo '$CURL is not a valid curl executable'
		 curl_failed
      fi
	  if [ -z "$download_url" ]; then 
	    echo 'Unable to determine the weblogic-deploy download url'
	    curl_failed
	  fi
  
      echo "Downloading the weblogic deploy tool install: ${download_url}/weblogic-deploy.zip"      
      ${CURL} -m 120 -Lo ${scriptDir}/weblogic-deploy.zip ${download_url}/weblogic-deploy.zip
      rc=$?
      if [ $rc != 0 ]; then echo "${CURL} failed with return code=${rc}"; return_code=$rc; curl_failed; fi
      ${JAVA_BIN}/jar tf ${scriptDir}/weblogic-deploy.zip &> /dev/null
      rc=$?
      if [ $rc != 0 ]; then 
	     echo "Downloaded an invalid or corrupted WDT install image : `ls -l ${scriptDir}/weblogic-deploy.zip`"
         if [ -f ${scriptDir}/weblogic-deploy.zip ]; then rm ${scriptDir}/weblogic-deploy.zip; fi
         curl_failed
      fi
    else
      echo 'Weblogic deploy tool already in the script directory. Bypass download'	
    fi  
    echo WDT Tool: `ls -l ${scriptDir}/weblogic-deploy.zip`	
}
 
# Determine the tag name for the resulting image using the value in the TAG_NAME.
# The setEnv.sh will set the TAG_NAME variable if the property is found in the
# properties file. This function should be called after the setEnv.sh is run
tag_name() {
   tagName=${CUSTOM_TAG_NAME:-12213-domain-home-in-image-wdt}
   #echo ${CUSTOM_TAG_NAME} and ${tagName}
}

curl_failed() {
      echo "Unable to download the weblogic deploy install using curl from location ${download_url}"
      echo "Manually download the install image weblogic.deploy.zip into location ${scriptDir} and re-run"
      clean_and_exit
}

wdturl() {
  githubRepo=${WDT_GITHUB_REPO}
  githubRelease=${WDT_VERSION:-$WDT_SUPPORTED_RELEASE}
  if [ "LATEST" != "${githubRelease}" ]; then githubRelease=weblogic-deploy-tooling-${githubRelease#weblogic-deploy-tooling-}; fi
  echo $(github_url)
}

github_url() {
    if [ "$githubRelease" == "LATEST" ]; then 
	   githubRelease=$(latest_release)
	   if [ "$?" -ne "0"]; then return $?; fi
	fi
	if [ -z "$githubRelease" ]; then return 1; fi
	echo https://github.com/${githubRepo}/releases/download/${githubRelease}
}

latest_release() {
  ${CURL} --silent "https://api.github.com/repos/${githubRepo}/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

set_up
download_tool
build_domain_image
rc=$?
clean_and_exit $rc