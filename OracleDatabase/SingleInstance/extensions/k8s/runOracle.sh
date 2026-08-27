#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Runs the Oracle Database inside the container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

export ORACLE_SID=${ORACLE_SID:-ORCLCDB}
ORACLE_SID=${ORACLE_SID^^}
EXTENSION_SCRIPT_DIR="${EXTENSION_SCRIPT_DIR:-/opt/oracle/scripts/extensions/k8s}"
LOCKING_SCRIPT_PATH="${EXTENSION_SCRIPT_DIR}/${LOCKING_SCRIPT:-lock.py}"

if [ ! -f "$LOCKING_SCRIPT_PATH" ]; then
    LOCKING_SCRIPT_PATH="$ORACLE_BASE/$LOCKING_SCRIPT"
fi

if [ "$DG_OBSERVER_ONLY" = "false" ]; then
    "$LOCKING_SCRIPT_PATH" --acquire --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.create_lck" --block
fi
