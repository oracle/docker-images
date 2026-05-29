#!/bin/bash
#
# LICENSE UPL 1.0
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#

if grep -q "Oracle Linux Server release 9" /etc/oracle-release; then \
        dnf -y install oracle-ai-database-preinstall-26ai && \
        rm -f /etc/systemd/system/oracle-ai-database-preinstall-26ai-firstboot.service && \
        dnf clean all; \
else \
        dnf -y install oraclelinux-developer-release-el8 && \
        dnf -y install oracle-ai-database-preinstall-26ai && \
	rm -f /etc/systemd/system/oracle-ai-database-preinstall-26ai-firstboot.service && \
        dnf clean all; \
fi && \
dnf -y install net-tools zip unzip tar openssl openssh-server vim-minimal which passwd sudo python3 hostname fontconfig lsof  && \
dnf clean all && \
chmod ug+x $SCRIPT_DIR/*.sh && \
rm -f /etc/sysctl.conf && \
rm -f /usr/lib/systemd/system/dnf-makecache.service
