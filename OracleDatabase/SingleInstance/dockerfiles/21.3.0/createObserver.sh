#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: abhishek.by.kumar@oracle.com
# Description: Creates Data Guard Observer using the following parameters:
#              $OBSERVER_NAME: Name of the observer
#              $PRIMARY_DB_CONN_STR: Connection string to connect with primary database
#              $ORACLE_PWD: The Oracle password for sys user of the primary database
#              $OBSERVER_BASE_DIR: Base directory to store observer data, log files
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -e

# Auto generate the observer name if not given
export OBSERVER_NAME=${1:-"OBSERVER-`openssl rand -hex 4`"}

# Validation: Check if PRIMARY_DB_CONN_STR is provided or not
if [ -z "${PRIMARY_DB_CONN_STR}" ]; then
echo "ERROR: Please provide PRIMARY_DB_CONN_STR to connect with primary database. Exiting..."
exit 1
fi

# Validation: Check if ORACLE_PWD (which is password for sys user of the primary database) is provided or not
if [ -z "${ORACLE_PWD}" ]; then
echo "ERROR: Please provide sys user password of primary database as ORACLE_PWD. Exiting..."
exit 1
fi

# Setting up directory for Observer configuration and log file
export OBSERVER_DIR="${OBSERVER_BASE_DIR}/${OBSERVER_NAME}"
mkdir -p ${OBSERVER_DIR}

# Starting observer in background
nohup dgmgrl -echo sys/${ORACLE_PWD}@${PRIMARY_DB_CONN_STR} "START OBSERVER ${OBSERVER_NAME} FILE IS ${OBSERVER_DIR}/fsfo.dat LOGFILE IS${OBSERVER_DIR}/observer.log" > ${OBSERVER_DIR}/nohup.out &
