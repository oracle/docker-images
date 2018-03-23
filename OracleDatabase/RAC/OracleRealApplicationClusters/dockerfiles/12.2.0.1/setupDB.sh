#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Create Directories
mkdir -p $DB_BASE
mkdir -p $DB_HOME

usermod -g oinstall -G oinstall,dba,oper,backupdba,dgdba,kmdba,asmdba,racdba,asmadmin oracle

chown -R oracle:oinstall $DB_BASE
chown -R oracle:oinstall $DB_HOME
chown -R oracle:oinstall $INSTALL_SCRIPTS
chmod 775 $INSTALL_SCRIPTS

echo "export ORACLE_HOME=$DB_HOME" >> /home/oracle/.bashrc
echo "export PATH=$DB_PATH" >> /home/oracle/.bashrc
echo "export LD_LIBRARY_PATH=$DB_LD_LIBRARY_PATH" >> /home/oracle/.bashrc
echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/oracle/.bashrc
echo "export GRID_HOME=$GRID_HOME" >> /home/oracle/.bashrc
echo "export DB_HOME=$DB_HOME" >> /home/oracle/.bashrc
