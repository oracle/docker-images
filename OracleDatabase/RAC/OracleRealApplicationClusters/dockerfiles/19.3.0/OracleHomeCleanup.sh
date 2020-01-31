#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2019
# Author: paramdeep.saini@oracle.com
# Description: Cleanup the $ORACLE_HOME and ORACLE_BASE after Grid confguration in the image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Image Cleanup Script

source /home/${DB_USER}/.bashrc
ORACLE_HOME=${DB_HOME}

rm -rf $ORACLE_HOME/bin/extjob
rm -rf $ORACLE_HOME/PAF
rm -rf $ORACLE_HOME/install/oratab
rm -rf $ORACLE_HOME/install/make.log
rm -rf $ORACLE_HOME/network/admin/listener.ora
rm -rf $ORACLE_HOME/network/admin/tnsnames.ora
rm -rf $ORACLE_HOME/bin/nmo
rm -rf $ORACLE_HOME/bin/nmb
rm -rf $ORACLE_HOME/bin/nmhs
rm -rf $ORACLE_HOME/log/.*
rm -rf $ORACLE_HOME/oc4j/j2ee/oc4j_applications/applications/em/em/images/chartCache/*
rm -rf $ORACLE_HOME/rdbms/audit/*
rm -rf $ORACLE_HOME/cfgtoollogs/*
rm -rf $ORACLE_HOME/inventory/Scripts/comps.xml.*
rm -rf $ORACLE_HOME/inventory/Scripts/oraclehomeproperties.xml.*
rm -rf $ORACLE_HOME/inventory/Scripts/oraInst.loc.*
rm -rf $ORACLE_HOME/inventory/Scripts/inventory.xml.*
