#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------

# Setup environment for GoldenGate.   Also install rlwrap, vim and Java 1.8 for other requirements.
mkdir -p $OGG_INSTALL_DIR && \
chown -R oracle:oinstall $INSTALL_DIR && \
chown -R oracle:oinstall $OGG_INSTALL_DIR && \
chmod ug+x $INSTALL_DIR && \
chmod ug+x $OGG_INSTALL_DIR && \
wget http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
rpm -Uvh epel-release-latest-7.noarch.rpm && \
yum -y -q install rlwrap && \
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.rpm" && \
yum -y -q localinstall jdk-8u60-linux-x64.rpm && \
yum -y -q install vim-enhanced && \
yum clean all && \
rm epel-release-latest-7.noarch.rpm && \
rm jdk-8u60-linux-x64.rpm
