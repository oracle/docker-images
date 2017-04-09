#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2017
# Author: rick.michaud@oracle.com
# Description: Sets up the unix environment for OGG installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

# Replace place holders
# ---------------------
sed -i -e "s|###OGG_INSTALL_DIR###|$OGG_INSTALL_DIR|g" $INSTALL_DIR/$OGG_INSTALL_RSP && \
cd $INSTALL_DIR       && \
unzip $OGG_INSTALL_FILE && \
rm $OGG_INSTALL_FILE    && \
$INSTALL_DIR/fbo_ggs_Linux_x64_shiphome/Disk1/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_DIR/$OGG_INSTALL_RSP -ignoresysprereqs -ignoreprereq && \
rm -rf $INSTALL_DIR/fbo_ggs_Linux_x64_shiphome
