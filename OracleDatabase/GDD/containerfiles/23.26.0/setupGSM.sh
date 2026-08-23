#!/bin/bash
#
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#

# Create Directories
mkdir -p $GSM_BASE
mkdir -p $GSM_HOME
mkdir -p $INVENTORY

chown -R oracle:oinstall $INVENTORY
chown -R oracle:oinstall $GSM_BASE
chown -R oracle:oinstall $GSM_HOME
chown -R oracle:oinstall $INSTALL_SCRIPTS
chmod 775 $INSTALL_SCRIPTS

chmod 666 /etc/sudoers
echo "oracle       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

echo "export ORACLE_HOME=$GSM_HOME" >> /home/oracle/.bashrc
echo "export PATH=$GSM_PATH" >> /home/oracle/.bashrc
echo "export LD_LIBRARY_PATH=$GSM_LD_LIBRARY_PATH" >> /home/oracle/.bashrc
echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/oracle/.bashrc
echo "export GSM_HOME=$GSM_HOME" >> /home/oracle/.bashrc
