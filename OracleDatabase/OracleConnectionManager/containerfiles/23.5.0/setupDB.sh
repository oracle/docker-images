#!/bin/bash
#
#############################
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Create Directories
mkdir -p $DB_BASE
mkdir -p $DB_HOME
mkdir -p $INVENTORY

chown -R oracle:oinstall $INVENTORY
chown -R oracle:oinstall $DB_BASE
chown -R oracle:oinstall $DB_HOME
chown -R oracle:oinstall $INSTALL_SCRIPTS
chmod 775 $INSTALL_SCRIPTS

chmod 666 /etc/sudoers
echo "oracle       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

echo "export ORACLE_HOME=$DB_HOME" >> /home/oracle/.bashrc
echo "export PATH=$DB_PATH" >> /home/oracle/.bashrc
echo "export LD_LIBRARY_PATH=$DB_LD_LIBRARY_PATH" >> /home/oracle/.bashrc
echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/oracle/.bashrc
echo "export DB_HOME=$DB_HOME" >> /home/oracle/.bashrc
