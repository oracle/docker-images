#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2022 Oracle and/or its affiliates.
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
elif command -v yum >/dev/null 2>&1; then
    PKG_MGR=yum
elif command -v microdnf >/dev/null 2>&1; then
    PKG_MGR=microdnf
else
    echo "ERROR: no supported package manager found (dnf, yum, or microdnf)" >&2
    exit 1
fi

"$PKG_MGR" update -y && \
"$PKG_MGR" clean all && \

chmod ug+x "$SCRIPT_DIR"/*.sh && \
packages=(oracle-database-preinstall-21c net-tools which zip unzip tar openssh-server openssh-clients vim-minimal passwd sudo) && \
if [ "$PKG_MGR" = microdnf ]; then
    "$PKG_MGR" install -y "${packages[@]}"
else
    "$PKG_MGR" -y install "${packages[@]}"
fi && \
"$PKG_MGR" clean all
