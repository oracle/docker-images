#!/bin/sh
# Author: hemastuti.baruah@oracle.com
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#Script used to restart OHS
#  WLST_HOME    - The root directory of your WLST utility
#*************************************************************************
echo "MW_HOME=${MW_HOME:?"Please set MW_HOME"}"
echo "ORACLE_HOME=${ORACLE_HOME:?"Please set ORACLE_HOME"}"
export MW_HOME ORACLE_HOME

#Set WLST_HOME, JAVA_HOME
WLST_HOME=${ORACLE_HOME}/oracle_common/common/bin
export WLST_HOME

JAVA_HOME=${ORACLE_HOME}/oracle_common/jdk/jre
export JAVA_HOME
################################################################
echo "Going to Restart OHS server"
${WLST_HOME}/wlst.sh /u01/oracle/container-scripts/restart-ohs.py