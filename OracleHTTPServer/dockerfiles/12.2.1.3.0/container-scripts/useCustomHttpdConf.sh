#!/bin/bash
# Author: Rajesh.G.Gupta@oracle.com
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#*************************************************************************
#This script will override Oracle Http Server config (httpd.conf),
#in order to enable the Oracle HTTP Server instances to route applications
#deployed on the Admin Server, Single Managed Server or the Oracle WebLogic Server clusters
#Refer to Section 2.4 @ http://docs.oracle.com/middleware/12213/webtier/develop-plugin/oracle.htm#PLGWL553
#
#Prerequisite:
#1.Create a directory which would be mounted to the container
#2.Create "custom_httpd.conf"  as per your environment by referring to httpd.conf file included in the OHS Image and OHS document above
#3.Place the "custom_httpd.conf" inside the directory which will be mounted in the container
#4.During OHS container creation mount the directory  which contains the "custom_httpd.conf"
#
# Note :
# If custom_httpd.conf is not provided, WebLogic Http Server will use the default configuration
#
#MW_HOME    - The root directory of your OHS standalone install
#DOMAIN_NAME - Env Value set by Dockerfile , default is "ohsDomain"
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
httpdconfigfile=`find /config -name 'custom_httpd.conf' 2>&1 | grep -v 'Permission denied'`
export httpdconfigfile
echo "HTTPDCONFIGFILE IS ${httpdconfigfile}"

# Check and copy custom_mod_wl_ohs.conf to OHS Instance Home
if [[ -n "${httpdconfigfile/[ ]*\n/}" ]]; then
cd ${INSTANCE_CONFIG_HOME}
mv httpd.conf httpd.conf.ORIGINAL
echo "Copying ${httpdconfigfile} to ${INSTANCE_CONFIG_HOME} "
cp ${httpdconfigfile} ${INSTANCE_CONFIG_HOME}/httpd.conf
fi
