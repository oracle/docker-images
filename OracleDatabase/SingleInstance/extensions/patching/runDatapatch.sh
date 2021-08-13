#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2020
# Author: rishabh.y.gupta@oracle.com
# Description: Runs datapatch in a container while using existing datafiles if container is at different RU level
#              than the container which created the datafiles
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# LSPATCHES_FILE will have the patch summary of the datafiles.
DBCONFIG_DIR="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}"
LSPATCHES_FILE="${DBCONFIG_DIR}/${ORACLE_SID}.lspatches"

# tmp.lspatches will have the patch summary of the oracle home.
temp_lspatches_file="/tmp/tmp.lspatches"
$ORACLE_HOME/OPatch/opatch lspatches > ${temp_lspatches_file};

if diff ${LSPATCHES_FILE} ${temp_lspatches_file} 2> /dev/null; then
    echo "Datafiles are already patched. Skipping datapatch run."
else
    echo "Running datapatch...";
    if ! $ORACLE_HOME/OPatch/datapatch -skip_upgrade_check; then
        echo "Datapatch execution has failed.";
        exit 1;
    else
        echo "DONE: Datapatch execution."
        cp ${temp_lspatches_file} ${LSPATCHES_FILE};
    fi
fi
