#!/bin/sh
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
# Description: script to set environment for running OIG containers
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#
#===============================================
# MUST: Customize this to your local env
#===============================================
#
# Directory where all domains/db data etc are
# kept. Directories will be created here
export DC_USERHOME=/scratch/${USER}/docker/OIG

# Registry names where requisite standard images
# can be found
export DC_REGISTRY_OIG="localhost"
export DC_REGISTRY_DB="localhost"
export DC_DB_VERSION="19.3.0.0-ee"

# Proxy Environment
export http_proxy=""
export https_proxy=""
export no_proxy=""
export http_proxy=""

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
  export DC_ORCL_SID=oimdb
  export DC_ORCL_PDB=oimpdb
  export DC_ORCL_SYSPWD=
  export DC_ORCL_HOST=oimdb
  #
  export DC_ORCL_DBDATA=${DC_USERHOME}/dbdata
  #
  # AdminServer Password
  #
  export DC_ADMIN_PWD=
  export OIG_IMAGE=oig:latest
  #
  # RCU Common password for all schemas + Prefix Names
  #
  export DC_RCU_SCHPWD=
  export DC_RCU_OIMPFX=OIM03
  #
  # Domain directories for the various domain types
  #
  export DC_DDIR_OIM=${DC_USERHOME}/oimdomain
}

#===============================================
createDirs() {
  mkdir -p  ${DC_DDIR_OIM}
  chmod 777  ${DC_DDIR_OIM}
  mkdir -p ${DC_ORCL_DBDATA}
  chmod 777 ${DC_ORCL_DBDATA}
}

#===============================================
#== MAIN starts here
#===============================================
#
echo "INFO: Setting up OIM Docker Environment..."
exportComposeEnv
createDirs
echo "INFO: Environment variables"
env | grep -e "DC_" | sort
