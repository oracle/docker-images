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
#Prerequisite: Provide WLS Host, Port and Cluster info in the env.list during docker run
#
#MW_HOME    - The root directory of your OHS standalone install
#DOMAIN_NAME - Env Value set by Dockerfile , default is "ohsDOmain"
#OHS_COMPONENT_NAME - Env Value set by Dockerfile , default is "ohs_sa1"
#WEBLOGIC_HOST, WEBLOGIC_PORT, WEBLOGIC_CLUSTER - Env values passed from env.list
#*************************************************************************
echo "MW_HOME=${MW_HOME:?"Please set MW_HOME"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME"}"
echo "OHS_COMPONENT_NAME=${OHS_COMPONENT_NAME:?"Please set OHS_COMPONENT_NAME"}"
echo "WEBLOGIC_HOST=${WEBLOGIC_HOST:?"Please provide Weblogic Admin Server hostname in the env.list file"}"
echo "WEBLOGIC_PORT=${WEBLOGIC_PORT:?"Please provide Weblogic Admin Server Port in the env.list file"}"
echo "WEBLOGIC_CLUSTER=${WEBLOGIC_CLUSTER:?"Please provide the Weblogic Cluster details in the env.list file"}"

DOMAIN_HOME=${MW_HOME}/user_projects/domains/${DOMAIN_NAME}
INSTANCE_CONFIG_HOME=$DOMAIN_HOME/config/fmwconfig/components/OHS/${OHS_COMPONENT_NAME}
export INSTANCE_CONFIG_HOME
echo "INSTANCE_CONFIG_DIR=${INSTANCE_CONFIG_HOME}"

#Start NodeManager and OHS server
/u01/oracle/container-scripts/startNMandOHS.sh


#Modify the variables in the mod_wl_ohs.conf.sample file with values provided in the env.file
cp /u01/oracle/container-scripts/mod_wl_ohs.conf.sample /u01/oracle/container-scripts/mod_wl_ohs.conf.sample.without_substitution
sed -i -e "s/WEBLOGIC_HOST/$WEBLOGIC_HOST/g" -e "s/WEBLOGIC_PORT/$WEBLOGIC_PORT/g" -e "s/WEBLOGIC_CLUSTER/$WEBLOGIC_CLUSTER/g" mod_wl_ohs.conf.sample

# Rename the original file and copy the sample file to instance config lcoation
cd ${INSTANCE_CONFIG_HOME}
mv mod_wl_ohs.conf mod_wl_ohs.conf.ORIGINAL
echo "Copying plugin file to INSTANCE_CONFIG_DIR=${INSTANCE_CONFIG_HOME}"
cp /u01/oracle/container-scripts/mod_wl_ohs.conf.sample ${INSTANCE_CONFIG_HOME}/mod_wl_ohs.conf

# Restart ohs server
/u01/oracle/container-scripts/restartOHS.sh

#Tail all servr logs
tail -f ${DOMAIN_HOME}/nodemanager/nodemanager.log ${DOMAIN_HOME}/servers/*/logs/*.out