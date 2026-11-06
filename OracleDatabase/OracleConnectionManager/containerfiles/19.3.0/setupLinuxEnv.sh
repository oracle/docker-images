#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR=dnf
else
    PKG_MGR=yum
fi

"$PKG_MGR" update -y && \
"$PKG_MGR" clean all && \

chmod ug+x "$SCRIPT_DIR"/*.sh && \
"$PKG_MGR" -y install \
    oracle-database-preinstall-19c \
    net-tools \
    which \
    zip \
    unzip \
    tar \
    openssh-server \
    openssh-clients \
    vim-minimal \
    passwd \
    sudo && \
"$PKG_MGR" clean all && \
rm -rf /var/cache/yum
