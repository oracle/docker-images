#!/bin/bash
# shellcheck disable=SC2034,SC2166,SC2155,SC1090,SC2046,SC2178,SC2207,SC2163,SC2115,SC2173,SC1091,SC1143,SC2164,SC3014
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2022 Oracle and/or its affiliates.
# 
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Runs the Oracle RAC Database inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

if [ -z ${BASE_DIR} ]; then
   BASE_DIR=/opt/scripts/startup/scripts
else
  BASE_DIR=$SCRIPT_DIR/scripts
fi

if [ -z ${MAIN_SCRIPT} ]; then
    SCRIPT_NAME="main.py"
fi

if [ -z ${EXECUTOR} ]; then
    EXECUTOR="python3"
fi

cd $BASE_DIR
$EXECUTOR $SCRIPT_NAME

# Tail on alert log and wait (otherwise container will exit)
