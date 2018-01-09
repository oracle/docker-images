#!/bin/sh
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
export DC_REGISTRY_SOA="localhost"
export DC_REGISTRY_DB="localhost"

# Proxy Environment
#export http_proxy=""
#export https_proxy=""
#export no_proxy=""

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
  export DC_ORCL_SID=soadb
  export DC_ORCL_PDB=soapdb
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
  export DC_RCU_SOAPFX=SOA01
  export DC_RCU_BPMPFX=BPM01
  export DC_RCU_OSBPFX=OSB01
  #
  # Domain directories for the various domain types
  #
  export DC_DDIR_SOA=${DC_USERHOME}/soadomain
  export DC_DDIR_BPM=${DC_USERHOME}/bpmdomain
  export DC_DDIR_OSB=${DC_USERHOME}/osbdomain
  #
  # Default version to use for compose images
  #
  export DC_SOA_VERSION=12.2.1.3
}

#===============================================
createDirs() {
  mkdir -p ${DC_ORCL_DBDATA} ${DC_DDIR_SOA} ${DC_DDIR_BPM} ${DC_DDIR_OSB}
  chmod 777 ${DC_ORCL_DBDATA} ${DC_DDIR_SOA} ${DC_DDIR_BPM} ${DC_DDIR_OSB}
}

#===============================================
#== MAIN starts here
#===============================================
#
echo "INFO: Setting up SOA Docker Environment..."
exportComposeEnv
createDirs
#echo "INFO: Environment variables"
#env | grep -e "DC_" | sort
