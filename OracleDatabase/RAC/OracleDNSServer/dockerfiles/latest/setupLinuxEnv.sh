#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2017,2021 Oracle and/or its affiliates.
#
# Since: January, 2017
# Author: sanjay.singh@oracle.com,  paramdeep.saini@oracle.com
# Description:
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# ------------------------------------------------------------
chmod ug+x /opt/scripts/startup/*.sh && \
yum -y install systemd hostname sudo bind bind-utils bind-chroot net-tools which zip unzip tar openssh-server openssh-client vim-minimal which passwd  && \
yum clean all 
