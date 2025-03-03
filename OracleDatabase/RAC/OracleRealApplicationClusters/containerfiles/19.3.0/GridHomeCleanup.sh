#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2019,2025 Oracle and/or its affiliates.
#
# Since: January, 2019
# Author: paramdeep.saini@oracle.com
# Description: Cleanup the $GRID_HOME and ORACLE_BASE after Grid confguration in the image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Image Cleanup Script
# shellcheck disable=SC1090
source /home/"${GRID_USER}"/.bashrc
# shellcheck disable=SC2034
ORACLE_HOME=${GRID_HOME}

rm -rf /u01/app/grid/*
rm -rf "$GRID_HOME"/log
rm -rf "$GRID_HOME"/logs
rm -rf "$GRID_HOME"/crs/init
rm -rf "$GRID_HOME"/crs/install/rhpdata
rm -rf "$GRID_HOME"/crs/log
rm -rf "$GRID_HOME"/racg/dump
rm -rf "$GRID_HOME"/srvm/log
rm -rf "$GRID_HOME"/cv/log
rm -rf "$GRID_HOME"/cdata
rm -rf "$GRID_HOME"/bin/core*
rm -rf "$GRID_HOME"/bin/diagsnap.pl
rm -rf "$GRID_HOME"/cfgtoollogs/*
rm -rf "$GRID_HOME"/network/admin/listener.ora
rm -rf "$GRID_HOME"/crf
rm -rf "$GRID_HOME"/ologgerd/init
rm -rf "$GRID_HOME"/osysmond/init
rm -rf "$GRID_HOME"/ohasd/init
rm -rf "$GRID_HOME"/ctss/init
rm -rf "$GRID_HOME"/dbs/.*.dat
rm -rf "$GRID_HOME"/oc4j/j2ee/home/log
rm -rf "$GRID_HOME"/inventory/Scripts/ext/bin/log
rm -rf "$GRID_HOME"/inventory/backup/*
rm -rf "$GRID_HOME"/mdns/init
rm -rf "$GRID_HOME"/gnsd/init
rm -rf "$GRID_HOME"/evm/init
rm -rf "$GRID_HOME"/gipc/init
rm -rf "$GRID_HOME"/gpnp/gpnp_bcp.*
rm -rf "$GRID_HOME"/gpnp/init
rm -rf "$GRID_HOME"/auth
rm -rf "$GRID_HOME"/tfa
rm -rf "$GRID_HOME"/suptools/tfa/release/diag
rm -rf "$GRID_HOME"/rdbms/audit/*
rm -rf "$GRID_HOME"/rdbms/log/*
rm -rf "$GRID_HOME"/network/log/*
rm -rf "$GRID_HOME"/inventory/Scripts/comps.xml.*
rm -rf "$GRID_HOME"/inventory/Scripts/oraclehomeproperties.xml.*
rm -rf "$GRID_HOME"/inventory/Scripts/oraInst.loc.*
rm -rf "$GRID_HOME"/inventory/Scripts/inventory.xml.*
rm -rf "$GRID_HOME"/log_file_client.log
rm -rf "$INVENTORY"/logs/*
