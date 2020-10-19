#!/bin/sh
#
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#
# Description: script to build a Docker image for Oracle Access Manager 
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#
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

export DC_REGISTRY_OAM="localhost"
export DC_REGISTRY_DB="localhost"


# Proxy Environment
export NO_PROXY=
export no_proxy=
export http_proxy=
export https_proxy=
export HTTPS_PROXY=
export HTTP_PROXY=
export ftp_proxy=
export FTP_PROXY=
#===============================================
exportComposeEnv() {
  #
  export DC_HOSTNAME=`hostname -f`
  #
  # Used by Docker Compose from the env
  # Oracle DB Parameters
  #
  export DC_ORCL_PORT=1521
  export DC_ORCL_OEM_PORT=5500
  export DC_ORCL_SID=oamdb
  export DC_ORCL_PDB=oampdb
  export DC_ORCL_SYSPWD=
  export DC_ORCL_HOST=${DC_HOSTNAME}
  #
  export DC_ORCL_DBDATA=${DC_USERHOME}/dbdata
  #
  # AdminServer Password
  #
  export DC_ADMIN_PWD=
  #
  # RCU Common password for all schemas + Prefix Names
  #
  export DC_RCU_SCHPWD=
  export DC_RCU_OAMPFX=OAM01
  #
  # Domain directories for the various domain types
  #
  export DC_DDIR_OAM=${DC_USERHOME}/oamdomain
  export DC_OAM_VERSION=12.2.1.4.0
  export DC_ADMIN_USER=weblogic
  export DC_DB_DOMAIN=us.oracle.com
}

#===============================================
createDirs() {
  mkdir -p ${DC_ORCL_DBDATA} ${DC_DDIR_OAM}
  chmod 777 ${DC_ORCL_DBDATA} ${DC_DDIR_OAM}
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
