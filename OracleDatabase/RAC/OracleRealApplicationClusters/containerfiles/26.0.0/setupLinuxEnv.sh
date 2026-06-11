#!/bin/bash
# shellcheck disable=SC2034,SC2166,SC2155,SC1090,SC2046,SC2178,SC2207,SC2163,SC2115,SC2173,SC1091,SC1143,SC2164,SC3014
# LICENSE UPL 1.0
#
# Copyright (c) 2018 - 2024 Oracle and/or its affiliates.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# ------------------------------------------------------------
## Use OCI yum repos on OCI instead of public yum
region=$(curl --noproxy '*' -sfm 3 -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | sed -nE 's/^ *"regionIdentifier": "([^"]+)".*/\1/p')
if [ -n "$region" ]; then 
    echo "Detected OCI Region: $region"
    for proxy in $(printenv | grep -i _proxy | cut -d= -f1); do unset $proxy; done
    echo "-$region" > /etc/yum/vars/ociregion
fi 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
mkdir /asmdisks && \
mkdir /responsefiles  && \
chmod ug+x /opt/scripts/startup/*.sh && \

if grep -q "Oracle Linux Server release 9" /etc/oracle-release; then \
       # curl --noproxy '*' https://ca-artifacts.oraclecorp.com/auto-build/x86_64-build-output-9-dev/oracle-database-preinstall-23ai-1.0-2.el9.x86_64.rpm  --output oracle-database-preinstall-23ai-1.0-2.el9.x86_64.rpm  && \
       # dnf install -y oracle-database-preinstall-23ai-1.0-2.el9.x86_64.rpm cronie && \
        dnf install -y oracle-ai-database-preinstall-26ai && \
        cp /etc/security/limits.d/oracle-ai-database-preinstall-26ai.conf /etc/security/limits.d/grid-database-preinstall-26ai.conf && \
        sed -i 's/oracle/grid/g' /etc/security/limits.d/grid-database-preinstall-26ai.conf && \
        rm -f /etc/systemd/system/oracle-ai-database-preinstall-26ai-firstboot.service && \
        sed -i 's/^TasksMax\S*/TasksMax=80%/g' /usr/lib/systemd/system/user-.slice.d/10-defaults.conf && \
        dnf clean all; \
else \
        dnf -y install oraclelinux-developer-release-el8 && \
        dnf -y install oracle-ai-database-preinstall-26ai libnsl cronie && \
        cp /etc/security/limits.d/oracle-ai-database-preinstall-26ai.conf /etc/security/limits.d/grid-database-preinstall-26ai.conf && \
        sed -i 's/oracle/grid/g' /etc/security/limits.d/grid-database-preinstall-26ai.conf && \
        rm -f /etc/rc.d/init.d/oracle-database-preinstall-26ai-firstboot && \
        dnf clean all; \
fi && \
dnf -y install systemd vim passwd expect sudo passwd openssl openssh-server hostname python3 rsync fontconfig lsof  && \
dnf clean all && \
rm -f /etc/sysctl.conf && \
rm -f /usr/lib/systemd/system/dnf-makecache.service
