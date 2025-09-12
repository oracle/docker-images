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
region=$(curl --noproxy '*' -sfm 3 -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | sed -nE 's/^ *"regionIdentifier": "([^"]+)".*/\1/p')
if [ -n "$region" ]; then 
    echo "Detected OCI Region: $region"
    for proxy in $(printenv | grep -i _proxy | cut -d= -f1); do unset $proxy; done
    echo "-$region" > /etc/yum/vars/ociregion
fi 
# Refer Doc ID 2760289.1 for error- "libxcrypt-compat compat-openssl11" only available in OL9
# Error in invoking target 'libasmclntsh19.ohso libasmperl19.ohso client_sharedlib' of makefile '/u01/app/oracle/product/19c/dbhome_1/rdbms/lib/ins_rdbms.mk'.
mkdir /asmdisks && \
mkdir /responsefiles  && \
chmod ug+x /opt/scripts/startup/*.sh && \
yum -y install systemd oracle-database-preinstall-19c net-tools which zip  \
unzip tar openssl expect e2fsprogs openssh-server vim-minimal passwd which  \
sudo hostname policycoreutils-python-utils python3 lsof rsync libxcrypt-devel  \
libxcrypt  fontconfig libvirt-libs librdmacm libibverbs liblsan libasan \
libxcrypt-compat compat-openssl11 && \
yum clean all
