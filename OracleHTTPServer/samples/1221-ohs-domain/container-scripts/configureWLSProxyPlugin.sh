#!/bin/bash
# Author: hemastuti.baruah@oracle.com
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#*************************************************************************
#This script will configure Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs),
#in order to enable the Oracle HTTP Server instances to route applications
#deployed on the Admin Server, Single Managed Server or the Oracle WebLogic Server clusters
#Refer to Section 2.4 @ http://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553
#
#Prerequisite:
#1.Create docker volume e.g docker volume create --name volume
#2.Create "custom_mod_wl_ohs.conf"  as per your environment by referring to mod_wl_ohs.conf sample file and OHS document above
#3.Place the "custom_mod_wl_ohs.conf" inside the docker volume
#4.During OHS container creation mount the docker volume which contains the "custom_mod_wl_ohs.conf"
#
# Note :
# If custom_mod_wl_ohs.conf is not provided, WebLogic Server Proxy Plug-In will not be configured. But OHS server will be still running.
# User may login to OHS container and manually configure the WebLogic Server Proxy Plug-In later
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

#Search for the customized mod_wl_ohs.conf file
modwlsconfigfile=`find / -name 'custom_mod_wl_ohs.conf' 2>&1 | grep -v 'Permission denied'`
export modwlsconfigfile

# Check and copy custom_mod_wl_ohs.conf to OHS Instance Home
if [[ -n "${modwlsconfigfile/[ ]*\n/}" ]]; then
cd ${INSTANCE_CONFIG_HOME}
mv mod_wl_ohs.conf mod_wl_ohs.conf.ORIGINAL
echo "Copying ${modwlsconfigfile} to ${INSTANCE_CONFIG_HOME} "
cp ${modwlsconfigfile} ${INSTANCE_CONFIG_HOME}/mod_wl_ohs.conf
echo "Starting Node Manager and OHS server after successful configuration of WebLogic Server Proxy Plug-In "
/u01/oracle/container-scripts/startNMandOHS.sh
echo "You may now access the the application via OHS port 7777 @ http://localhost:7777/application_end_url"
#
# Incase custom_mod_wl_ohs.conf file is not provided/found, OHS will be started with default settings
else
echo "Customized mod_wl_ohs.conf file not found in mounted volume!!! WebLogic Server Proxy Plug-In has not been configured."
echo "Starting Node Manager and OHS server with default settings "
/u01/oracle/container-scripts/startNMandOHS.sh
echo "You may now access OHS @ http://localhost:7777/index.html"
fi