#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2020
# Author: rishabh.y.gupta@oracle.com
# Description: Relinks oracle binary in accordance with the edition passed by the user.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ "${ORACLE_EDITION}" != "" ]; then
    LIB_EDITION="$(/usr/bin/ar t $ORACLE_HOME/lib/libedtn$($ORACLE_HOME/bin/oraversion -majorVersion).a)"
    LIB_EDITION=$(echo ${LIB_EDITION} | cut -d. -f1)
    LIB_EDITION=${LIB_EDITION: -3}

    if [ "${ORACLE_EDITION,,}" == "enterprise" ]; then
        oracle_edition_in_short="ent"
    fi;

    if [ "${ORACLE_EDITION,,}" == "standard" ]; then
        oracle_edition_in_short="std"
    fi;

    if [ "${LIB_EDITION}" != "${oracle_edition_in_short}" ]; then
        echo "Relinking oracle binary for edition: ${ORACLE_EDITION}";
        cmd="make -f ${ORACLE_HOME}/rdbms/lib/ins_rdbms.mk edition_${ORACLE_EDITION,,} ioracle";
        echo "$cmd";
        $cmd;
    fi
fi