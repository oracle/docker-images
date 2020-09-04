#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2020
# Author: rishabh.y.gupta@oracle.com
# Description: Runs lspatches to save summary of installed patches just after new db is created.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

LSPATCHES_FILE="${ORACLE_SID}.lspatches"
LSPATCHES_FILE_PATH="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/${LSPATCHES_FILE}"

$ORACLE_HOME/OPatch/opatch lspatches > ${LSPATCHES_FILE_PATH};