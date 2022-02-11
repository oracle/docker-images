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

if [ "$DG_OBSERVER_ONLY" = "false" ]; then
    "$ORACLE_BASE/$LOCKING_SCRIPT" --acquire --file "$ORACLE_BASE/oradata/.${ORACLE_SID}.create_lck" --block
fi
