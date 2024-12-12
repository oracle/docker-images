#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

## Use OCI yum repos on OCI instead of public yum
region=$(curl --noproxy '*' -sfm 3 -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | sed -nE 's/^ *"regionIdentifier": "([^"]+)".*/\1/p')
if [ -n "$region" ]; then 
    echo "Detected OCI Region: $region"
    for proxy in $(printenv | grep -i _proxy | cut -d= -f1); do unset $proxy; done
    echo "-$region" > /etc/yum/vars/ociregion
fi 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
mkdir -p "$ORACLE_BASE"/scripts/setup && \
mkdir "$ORACLE_BASE"/scripts/startup && \
mkdir -p "$ORACLE_BASE"/scripts/extensions/setup && \
mkdir "$ORACLE_BASE"/scripts/extensions/startup && \
ln -s "$ORACLE_BASE"/scripts /docker-entrypoint-initdb.d && \
mkdir -p "$ORACLE_BASE"/oradata /home/oracle && \
mkdir -p "$ORACLE_HOME" && \
chmod ug+x "$ORACLE_BASE"/*.sh && \
dnf install -y oraclelinux-developer-release-el8 && \
dnf -y install oracle-database-preinstall-23ai openssl hostname file expect && \
rm -rf /var/cache/yum && \
ln -s "$ORACLE_BASE"/"$PWD_FILE" /home/oracle/ && \
echo oracle:oracle | chpasswd && \
chown -R oracle:dba "$ORACLE_BASE" && \
if [ "${ORACLE_SID}" = "FREE" ]; then
    sed -ie 's/^root:\*/root:/' /etc/shadow
fi
