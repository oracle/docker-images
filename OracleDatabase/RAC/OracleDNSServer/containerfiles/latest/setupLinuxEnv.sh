#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018-2025 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
chmod ug+x /opt/scripts/startup/*.sh && \
yum -y install systemd hostname sudo bind bind-utils bind-chroot net-tools which zip unzip tar openssh-server vim-minimal which passwd  && \
yum clean all 
