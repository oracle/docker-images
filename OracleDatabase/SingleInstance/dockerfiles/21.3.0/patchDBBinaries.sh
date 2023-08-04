#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2020
# Author: rishabh.y.gupta@oracle.com
# Description: Applies the patches provided by the user on the oracle home.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

RU_DIR="${PATCH_DIR}/release_update"
ONE_OFFS_DIR="${PATCH_DIR}/one_offs"

ru_files=("$RU_DIR"/*.zip)
ru_count=${#ru_files[@]}
if [ "$ru_count" -ge 2 ]; then
    echo "Error: Only 1 Release Update can be applied."
    exit 1;
elif [ "$ru_count" == 1 ]; then
    ru_patch="$(ls "$RU_DIR"/*.zip)"
    echo "Unzipping $ru_patch";
    unzip -qo "$ru_patch" -d "$PATCH_DIR";
    ru_patch=$(echo "${ru_patch##*/}" | cut -d_ -f1 | cut -dp -f2)
else
    echo "No Release Update to be installed."
fi

ONE_OFFS_LIST=()

if ls "$ONE_OFFS_DIR"/*.zip 2> /dev/null; then
    for patch_zip in "$ONE_OFFS_DIR"/*.zip; do
        patch_no=$(echo "${patch_zip##*/}" | cut -d_ -f1 | cut -dp -f2)
        if [ "$patch_no" == "6880880" ]; then
            echo "Removing directory ${ORACLE_HOME}/OPatch";
            rm -rf "${ORACLE_HOME}"/OPatch;
            echo "Unzipping OPatch archive $patch_zip to ${ORACLE_HOME}";
            unzip -qo "$patch_zip" -d "$ORACLE_HOME";
        else
            ONE_OFFS_LIST+=("$patch_no");
            echo "Unzipping $patch_zip";
            unzip -qo "$patch_zip" -d "$PATCH_DIR";
        fi
    done
else
    echo "No one-offs to be installed."
fi

export PATH=${ORACLE_HOME}/perl/bin:$PATH;

if [ -n "$ru_patch" ]; then
    echo "Applying Release Update: $ru_patch";
    cmd="${ORACLE_HOME}/OPatch/opatchauto apply -binary -oh $ORACLE_HOME ${PATCH_DIR}/${ru_patch} -target_type rac_database";
    echo "Running: $cmd";
    $cmd || {
        echo "RU application failed for patchset: ${ru_patch}";
        exit 1;
    }
fi

for patch in "${ONE_OFFS_LIST[@]}"; do
    echo "Applying patch: $patch";
    cmd="${ORACLE_HOME}/OPatch/opatchauto apply -binary -oh $ORACLE_HOME ${PATCH_DIR}/${patch} -target_type rac_database";
    echo "Running: $cmd";
    $cmd || {
        echo "Patch application failed for ${patch}";
        exit 1;
    }
done

# Remove not needed components
# APEX
rm -rf "$ORACLE_HOME"/apex && \
# ORDS
rm -rf "$ORACLE_HOME"/ords && \
# SQL Developer
rm -rf "$ORACLE_HOME"/sqldeveloper && \
# UCP connection pool
rm -rf "$ORACLE_HOME"/ucp && \
# All installer files
rm -rf "$ORACLE_HOME"/lib/*.zip && \
# OUI backup
rm -rf "$ORACLE_HOME"/inventory/backup/* && \
# Network tools help
rm -rf "$ORACLE_HOME"/network/tools/help && \
# Database upgrade assistant
rm -rf "$ORACLE_HOME"/assistants/dbua && \
# Database migration assistant
rm -rf "$ORACLE_HOME"/dmu && \
# Remove pilot workflow installer
rm -rf "$ORACLE_HOME"/install/pilot && \
# Support tools
rm -rf "$ORACLE_HOME"/suptools && \
# Temp location
rm -rf /tmp/* && \
# Database files directory
rm -rf "$INSTALL_DIR"/database
# Database patch directories
rm -rf "${PATCH_DIR:?}/"* "$ORACLE_HOME"/.patch_storage
