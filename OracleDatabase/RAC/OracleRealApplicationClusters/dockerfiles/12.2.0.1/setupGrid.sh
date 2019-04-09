#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for Grid installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

EDITION=$1

# Create Directories
mkdir -p $GRID_BASE
mkdir -p $GRID_HOME

groupadd -g 54334 asmadmin
groupadd -g 54335 asmdba
groupadd -g 54336 asmoper
useradd -u 54332 -g oinstall -G oinstall,asmadmin,asmdba,asmoper,racdba,dba  grid

chown -R grid:oinstall $GRID_BASE
chown -R grid:oinstall $GRID_HOME
mkdir -p $INVENTORY
chown -R grid:oinstall $INVENTORY

chmod 666 /etc/sudoers
echo "oracle       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
echo "grid       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

echo "export ORACLE_HOME=$GRID_HOME" >> /home/grid/.bashrc
echo "export PATH=$GRID_PATH" >> /home/grid/.bashrc
echo "export LD_LIBRARY_PATH=$GRID_LD_LIBRARY_PATH" >> /home/grid/.bashrc
echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/grid/.bashrc
echo "export GRID_HOME=$GRID_HOME" >> /home/grid/.bashrc
echo "export GRID_BASE=$GRID_BASE" >> /home/grid/.bashrc
echo "export DB_HOME=$DB_HOME" >> /home/grid/.bashrc
