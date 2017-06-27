#!/bin/sh
# Author: hemastuti.baruah@oracle.com
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#*************************************************************************
# script is used to start a NodeManager and OHS component server.
#  This script should be used only when node manager is configured per domain.
#  This script sets the following variables before starting
#  the node manager:
#
#  WL_HOME    - The root directory of your WebLogic installation
#  NODEMGR_HOME  - Absolute path to nodemanager directory under the configured domain home
#  DOMAIN_HOME - Absolute path to configured domain home
#  JAVA_HOME- Absolute path to jre inside the oracle home directory
#*************************************************************************
echo "MW_HOME=${MW_HOME:?"Please set MW_HOME"}"
echo "ORACLE_HOME=${ORACLE_HOME:?"Please set ORACLE_HOME"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME"}"
echo "OHS_COMPONENT_NAME=${OHS_COMPONENT_NAME:?"Please set OHS_COMPONENT_NAME"}"

export MW_HOME ORACLE_HOME DOMAIN_NAME OHS_COMPONENT_NAME


#Set WL_HOME, WLST_HOME, DOMAIN_HOME and NODEMGR_HOME
WL_HOME=${ORACLE_HOME}/wlserver
WLST_HOME=${ORACLE_HOME}/oracle_common/common/bin
echo "WLST_HOME=${WLST_HOME}"

DOMAIN_HOME=${ORACLE_HOME}/user_projects/domains/${DOMAIN_NAME}
export DOMAIN_HOME
echo "DOMAIN_HOME=${DOMAIN_HOME}"

NODEMGR_HOME=${DOMAIN_HOME}/nodemanager
export NODEMGR_HOME

echo "PATH=${PATH}"
PATH=$PATH:/usr/java/default/bin:/u01/oracle/ohssa/oracle_common/common/bin
export PATH
echo "PATH=${PATH}"

#  Set JAVA_OPTIONS and JAVA_HOME for node manager
JAVA_OPTIONS="${JAVA_OPTIONS} -Dweblogic.RootDirectory=${DOMAIN_HOME}"
export JAVA_OPTIONS

JAVA_HOME=${ORACLE_HOME}/oracle_common/jdk/jre
export JAVA_HOME

#Declare and initializing NMSTATUS
declare -a NMSTATUS
NMSTATUS[0]="NOT RUNNING"

# If nodemanager$$.log does not exists,this is the first time configuring the NM 
# generate the NM password 

if [ !  -f /u01/oracle/logs/nodemanager$$.log ]; then
    
# Auto generate node manager  password
NM_PASSWORD=$(date| md5sum | fold -w 8 | head -n 1) 

echo ""
echo "    NodeManager Password Auto Generated:"
echo ""
echo "      ----> 'OHS' Node Manager password: $NM_PASSWORD"
echo ""

sed -i -e "s|NM_PASSWORD|$NM_PASSWORD|g" /u01/oracle/container-scripts/create-sa-ohs-domain.py
sed -i -e "s|NM_PASSWORD|$NM_PASSWORD|g" /u01/oracle/container-scripts/start-ohs.py


# Create an empty ohs domain
wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/create-sa-ohs-domain.py
# Set the NM username and password in the properties file
echo "username=weblogic" >> /u01/oracle/ohssa/user_projects/domains/ohsDomain/config/nodemanager/nm_password.properties
echo "username=$NM_PASSWORD" >> /u01/oracle/ohssa/user_projects/domains/ohsDomain/config/nodemanager/nm_password.properties
mv /u01/oracle/container-scripts/helloWorld.html ${ORACLE_HOME}/user_projects/domains/ohsDomain/config/fmwconfig/components/OHS/ohs_sa1/htdocs/helloWorld.html
fi
