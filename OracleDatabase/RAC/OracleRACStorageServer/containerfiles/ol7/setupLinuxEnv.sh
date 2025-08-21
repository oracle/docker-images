#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2025 Oracle and/or its affiliates. All rights reserved.
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
mkdir /oradata && \
chmod ug+x /opt/scripts/startup/*.sh && \
yum -y install oracle-database-preinstall-18c  net-tools which zip unzip tar openssh-server openssh-client vim-minimal which vim-minimal passwd sudo  nfs-utils  && \
yum clean all 
