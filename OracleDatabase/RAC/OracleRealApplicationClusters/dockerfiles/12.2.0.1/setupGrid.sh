#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
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
useradd -u 54332 -g oinstall -G oinstall,asmadmin,asmdba,asmoper,racdba,dba  ${GRID_USER}

chown -R ${GRID_USER}:oinstall $GRID_BASE
chown -R ${GRID_USER}:oinstall $GRID_HOME
mkdir -p $INVENTORY
chown -R ${GRID_USER}:oinstall $INVENTORY

chmod 666 /etc/sudoers
echo "${DB_USER}       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
echo "${GRID_USER}       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

echo "export PATH=$GRID_PATH" >> /home/${GRID_USER}/.bashrc
echo "export LD_LIBRARY_PATH=$GRID_LD_LIBRARY_PATH" >> /home/${GRID_USER}/.bashrc
echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/${GRID_USER}/.bashrc
echo "export GRID_HOME=$GRID_HOME" >> /home/${GRID_USER}/.bashrc
echo "export GRID_BASE=$GRID_BASE" >> /home/${GRID_USER}/.bashrc
echo "export DB_HOME=$DB_HOME" >> /home/${GRID_USER}/.bashrc
