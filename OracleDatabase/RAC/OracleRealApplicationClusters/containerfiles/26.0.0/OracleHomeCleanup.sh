#!/bin/bash
# shellcheck disable=SC2034,SC2166,SC2155,SC1090,SC2046,SC2178,SC2207,SC2163,SC2115,SC2173,SC1091,SC1143,SC2164,SC3014
# LICENSE UPL 1.0
#
# Copyright (c) 2019,2021 Oracle and/or its affiliates.
#
# Since: January, 2019
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Cleanup the $ORACLE_HOME and ORACLE_BASE after Grid confguration in the image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Image Cleanup Script

source /home/"${DB_USER}"/.bashrc
ORACLE_HOME=${DB_HOME}

rm -rf "$ORACLE_HOME"/bin/extjob
rm -rf "$ORACLE_HOME"/PAF
rm -rf "$ORACLE_HOME"/install/oratab
rm -rf "$ORACLE_HOME"/install/make.log
rm -rf "$ORACLE_HOME"/network/admin/listener.ora
rm -rf "$ORACLE_HOME"/network/admin/tnsnames.ora
rm -rf "$ORACLE_HOME"/bin/nmo
rm -rf "$ORACLE_HOME"/bin/nmb
rm -rf "$ORACLE_HOME"/bin/nmhs
rm -rf "$ORACLE_HOME"/log/.*
rm -rf "$ORACLE_HOME"/oc4j/j2ee/oc4j_applications/applications/em/em/images/chartCache/*
rm -rf "$ORACLE_HOME"/rdbms/audit/*
rm -rf "$ORACLE_HOME"/cfgtoollogs/*
rm -rf "$ORACLE_HOME"/inventory/Scripts/comps.xml.*
rm -rf "$ORACLE_HOME"/inventory/Scripts/oraclehomeproperties.xml.*
rm -rf "$ORACLE_HOME"/inventory/Scripts/oraInst.loc.*
rm -rf "$ORACLE_HOME"/inventory/Scripts/inventory.xml.*
rm -rf "$INVENTORY"/logs/*
