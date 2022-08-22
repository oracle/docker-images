#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
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
yum -y install systemd oracle-database-preinstall-19c net-tools which zip unzip tar openssl expect e2fsprogs openssh-server vim-minimal passwd which sudo hostname policycoreutils-python-utils && \
yum clean all 

## Custom install to install xorg, perl, ntpd,crontab and hostname inside the container

#yum -y install systemd oracle-database-preinstall-19c net-tools ntpd crontab perl gcc hostname  which zip unzip tar openssl expect e2fsprogs openssh-server openssh-client vim-minimal passwd which sudo xorg-x11-server-Xorg xorg-x11-xauth xorg-x11-apps 
