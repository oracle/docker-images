#!/bin/bash
# shellcheck disable=all
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2025 Oracle and/or its affiliates.
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
mkdir /asmdisks && \
mkdir /responsefiles  && \
chmod ug+x /opt/scripts/startup/*.sh && \
dnf -y install oracle-database-preinstall-19c systemd vim-minimal passwd openssh-server hostname xterm xhost vi policycoreutils-python-utils lsof openssl libxcrypt-compat net-tools which zip unzip tar sudo && \
dnf clean all