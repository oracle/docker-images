#!/bin/sh
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
#===============================================
# MUST: Customize this to your local env
#===============================================
#
# Directory where all domains/db data etc are 
# kept. Directories will be created here
export DC_USERHOME=/scratch/${USER}/docker

# Registry names where requisite standard images
# can be found
export DC_REGISTRY=""

# Proxy Environment
# export NO_PROXY=""
# export no_proxy=""
# export http_proxy=""
# export https_proxy=""
# export HTTPS_PROXY=""
# export HTTP_PROXY=""
# export ftp_proxy=""
# export FTP_PROXY=""

#===============================================
exportComposeEnv() {
  #
  export DC_HOSTNAME=`hostname -f`

}

#===============================================
createDirs() {
  echo "INFO: crateDirs"
}

#===============================================
printEnvDetails() {
  echo "INFO: Environment variables"
  env | grep -e "DC_" | sort
}

#===============================================
#== MAIN starts here
#===============================================
#
echo "INFO: Setting up OAM Docker Environment..."
exportComposeEnv
createDirs
printEnvDetails
