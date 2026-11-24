#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -e

## Use OCI yum repos on OCI instead of public yum
region=$(curl --noproxy '*' -sfm 3 -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ 2>/dev/null | sed -nE 's/^ *"regionIdentifier": "([^"]+)".*/\1/p' || true)
if [ -n "$region" ]; then 
    echo "Detected OCI Region: $region"
    for proxy in $(printenv | grep -i _proxy | cut -d= -f1); do unset $proxy; done
    echo "-$region" > /etc/yum/vars/ociregion
fi 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
extra_packages=""
# Refer Doc ID 2760289.1: libxcrypt-compat is only available on Oracle Linux 9
if [ -f /etc/os-release ]; then
    ol_ver=$(grep -oP '^VERSION_ID="\K[0-9]+' /etc/os-release 2>/dev/null || true)
    if [ "$ol_ver" = "9" ]; then
        extra_packages="libxcrypt-compat"
    fi
fi

mkdir -p "$ORACLE_BASE"/scripts/setup && \
mkdir "$ORACLE_BASE"/scripts/startup && \
mkdir -p "$ORACLE_BASE"/scripts/extensions/setup && \
mkdir "$ORACLE_BASE"/scripts/extensions/startup && \
ln -s "$ORACLE_BASE"/scripts /docker-entrypoint-initdb.d && \
mkdir "$ORACLE_BASE"/oradata && \
mkdir -p "$ORACLE_HOME" && \
chmod ug+x "$ORACLE_BASE"/*.sh && \
yum update -y && \
yum -y install oracle-database-preinstall-19c openssl hostname $extra_packages && \
rm -rf /var/cache/yum && \
ln -s "$ORACLE_BASE"/"$PWD_FILE" /home/oracle/ && \
echo oracle:oracle | chpasswd && \
chown -R oracle:dba "$ORACLE_BASE"

if [ ! -f '/usr/bin/python' ] && [ -f '/usr/bin/python3' ]; then 
    alternatives --install /usr/bin/python python /usr/bin/python3 1; 
fi