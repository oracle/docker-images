#!/bin/bash
# Author: hemastuti.baruah@oracle.com
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#*************************************************************************
#This script will configure Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs),
#in order to enable the Oracle HTTP Server instances to route to applications
#deployed on the Oracle WebLogic Server clusters
#Refer to Section 2.4 @ http://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553
#
#Prerequisite: Edit the mod_wl_ohs.conf.sample provided for correct directives
#
#MW_HOME    - The root directory of your OHS standalone install
#DOMAIN_NAME - Env Value set by Dockerfile , default is "ohsDOmain"
#OHS_COMPONENT_NAME - Env Value set by Dockerfile , default is "ohs_sa1"
#*************************************************************************
echo "MW_HOME=${MW_HOME:?"Please set MW_HOME"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME"}"
echo "OHS_COMPONENT_NAME=${OHS_COMPONENT_NAME:?"Please set OHS_COMPONENT_NAME"}"

DOMAIN_HOME=${MW_HOME}/user_projects/domains/${DOMAIN_NAME}

INSTANCE_CONFIG_HOME=$DOMAIN_HOME/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}
export INSTANCE_CONFIG_HOME
echo "INSTANCE_CONFIG_DIR=${INSTANCE_CONFIG_HOME}"

# Rename the original file and copy the sample file to instance config lcoation
cd ${INSTANCE_CONFIG_HOME}
mv mod_wl_ohs.conf mod_wl_ohs.conf.ORIGINAL
echo "Copying plugin sample file to INSTANCE_CONFIG_DIR=${INSTANCE_CONFIG_HOME}"
cp /u01/oracle/container-scripts/mod_wl_ohs.conf.sample ${INSTANCE_CONFIG_HOME}/mod_wl_ohs.conf

# Restart ohs server
/u01/oracle/container-scripts/restartOHS.sh