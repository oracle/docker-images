#!/bin/bash
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
############################
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
mkdir /oradata && \
chmod ug+x /opt/scripts/startup/*.sh && \
if grep -q "Oracle Linux Server release 9" /etc/oracle-release; then \
        dnf install -y oracle-database-preinstall-23ai && \
        cp /etc/security/limits.d/oracle-database-preinstall-23ai.conf /etc/security/limits.d/grid-database-preinstall-23ai.conf && \
        sed -i 's/oracle/grid/g' /etc/security/limits.d/grid-database-preinstall-23ai.conf && \
        rm -f /etc/systemd/system/oracle-database-preinstall-23ai-firstboot.service && \
        sed -i 's/^TasksMax\S*/TasksMax=80%/g' /usr/lib/systemd/system/user-.slice.d/10-defaults.conf && \
        dnf clean all; \
else \
        dnf -y install oraclelinux-developer-release-el8 && \
        dnf -y install oracle-database-preinstall-23ai && \
        cp /etc/security/limits.d/oracle-database-preinstall-23ai.conf /etc/security/limits.d/grid-database-preinstall-23ai.conf && \
        sed -i 's/oracle/grid/g' /etc/security/limits.d/grid-database-preinstall-23ai.conf && \
        rm -f /etc/rc.d/init.d/oracle-database-preinstall-23ai-firstboot && \
        dnf clean all; \
fi && \
dnf -y install net-tools which zip unzip tar openssh-server vim-minimal which vim-minimal passwd sudo  nfs-utils  && \
dnf clean all  
