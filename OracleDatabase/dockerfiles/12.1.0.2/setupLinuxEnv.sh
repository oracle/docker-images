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
mkdir -p $ORACLE_BASE/oradata && \
chmod ug+x $ORACLE_BASE/$PWD_FILE && \
chmod ug+x $ORACLE_BASE/$RUN_FILE && \
chmod ug+x $ORACLE_BASE/$START_FILE && \
chmod ug+x $ORACLE_BASE/$CREATE_DB_FILE && \
yum -y install oracle-rdbms-server-12cR1-preinstall unzip wget tar openssl && \
yum clean all && \
echo oracle:oracle | chpasswd && \
chown -R oracle:dba $ORACLE_BASE
