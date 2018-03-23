#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
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
yum -y install oracle-database-server-12cR2-preinstall net-tools which zip unzip tar openssl expect e2fsprogs openssh-server openssh-client vim-minimal passwd which sudo && \
yum clean all 
