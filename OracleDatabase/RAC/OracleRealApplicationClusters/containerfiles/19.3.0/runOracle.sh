#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2025 Oracle and/or its affiliates.
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
# shellcheck disable=SC2164
cd $BASE_DIR
$EXECUTOR $SCRIPT_NAME

# Tail on alert log and wait (otherwise container will exit)
