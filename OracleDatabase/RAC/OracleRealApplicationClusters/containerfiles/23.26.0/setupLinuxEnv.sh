#!/bin/bash
# shellcheck disable=SC1143
# LICENSE UPL 1.0
#
# Copyright (c) 2018 - 2026 Oracle and/or its affiliates.
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

if grep -q "Oracle Linux Server release 9" /etc/oracle-release; then \
       # dnf install -y oracle-ai-database-preinstall-26ai-1.0-2.el9.x86_64.rpm cronie && \
        dnf install -y oracle-ai-database-preinstall-26ai && \
        cp /etc/security/limits.d/oracle-ai-database-preinstall-26ai.conf /etc/security/limits.d/grid-ai-database-preinstall-26ai.conf && \
        sed -i 's/oracle/grid/g' /etc/security/limits.d/grid-ai-database-preinstall-26ai.conf && \
        rm -f /etc/systemd/system/oracle-ai-database-preinstall-26ai-firstboot.service && \
        sed -i 's/^TasksMax\S*/TasksMax=80%/g' /usr/lib/systemd/system/user-.slice.d/10-defaults.conf && \
        dnf clean all; \
else \
        dnf -y install oraclelinux-developer-release-el8 && \
        dnf -y install oracle-ai-database-preinstall-26ai libnsl cronie && \
        cp /etc/security/limits.d/oracle-ai-database-preinstall-26ai.conf /etc/security/limits.d/grid-ai-database-preinstall-26ai.conf && \
        sed -i 's/oracle/grid/g' /etc/security/limits.d/grid-ai-database-preinstall-26ai.conf && \
        rm -f /etc/rc.d/init.d/oracle-ai-database-preinstall-26ai-firstboot && \
        dnf clean all; \
fi && \
dnf -y install systemd vim passwd expect sudo passwd openssl openssh-server hostname python3 rsync fontconfig lsof  && \
dnf clean all && \
rm -f /etc/sysctl.conf && \
rm -f /usr/lib/systemd/system/dnf-makecache.service
