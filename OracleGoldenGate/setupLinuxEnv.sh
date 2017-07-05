#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------

# Setup environment for GoldenGate.   
mkdir -p $OGG_INSTALL_DIR && \
chown -R oracle:oinstall $INSTALL_DIR && \
chown -R oracle:oinstall $OGG_INSTALL_DIR && \
chmod ug+x $INSTALL_DIR && \
chmod ug+x $OGG_INSTALL_DIR && \
yum -y -q install vim-enhanced && \
yum clean all 
