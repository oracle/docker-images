#!/bin/bash
# shellcheck disable=all
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2025 Oracle and/or its affiliates.
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
## Use OCI yum repos on OCI instead of public yum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGION_FILE="$SCRIPT_DIR/ociregion.sh"

if [ ! -f "$REGION_FILE" ]; then
    # Call the separate detection script if region file is missing
    "$SCRIPT_DIR/ociregion.sh"
fi

if [ -f "$REGION_FILE" ]; then
    region=$(cat "$REGION_FILE")
    echo "Loaded OCI Region from file: $region"
else
    echo "OCI Region file not found. Exiting."
    exit 1
fi
# Refer Doc ID 2760289.1 for error- "libxcrypt-compat compat-openssl11" only available in OL9
# Error in invoking target 'libasmclntsh19.ohso libasmperl19.ohso client_sharedlib' of makefile '/u01/app/oracle/product/19c/dbhome_1/rdbms/lib/ins_rdbms.mk'.
# Detect Oracle Linux version
if [ -f /etc/os-release ]; then
    ol_ver=$(grep -oP '^VERSION_ID="\K[0-9]+' /etc/os-release)
else
    echo "/etc/os-release not found. Cannot detect OS version."
    exit 1
fi

mkdir -p /asmdisks
mkdir -p /responsefiles
chmod ug+x /opt/scripts/startup/*.sh

if [ "$ol_ver" == "9" ]; then
    dnf -y install oracle-database-preinstall-19c systemd vim-minimal passwd openssh-server hostname xterm xhost vi \
    policycoreutils-python-utils lsof openssl libxcrypt-compat net-tools which zip unzip tar sudo rsync expect
    dnf clean all
elif [ "$ol_ver" == "8" ]; then
    yum -y install systemd oracle-database-preinstall-19c net-tools which zip unzip tar openssl expect e2fsprogs \
    openssh-server vim-minimal passwd which sudo hostname policycoreutils-python-utils python3 lsof rsync
    yum clean all
else
    echo "Unsupported Oracle Linux version: $ol_ver"
    exit 1
fi