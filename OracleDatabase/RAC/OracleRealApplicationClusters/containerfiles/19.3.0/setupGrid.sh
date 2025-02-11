#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2025 Oracle and/or its affiliates.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for Grid installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# shellcheck disable=SC2034
EDITION=$1

# Create Directories
if [ "${SLIMMING}x" != 'truex' ] ; then
      mkdir -p "$GRID_BASE"
      mkdir -p "$GRID_HOME"
fi

groupadd -g 54334 asmadmin
groupadd -g 54335 asmdba
groupadd -g 54336 asmoper
useradd -u 54332 -g oinstall -G oinstall,asmadmin,asmdba,asmoper,racdba,dba  "${GRID_USER}"

chmod 666 /etc/sudoers
echo "${DB_USER}       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
echo "${GRID_USER}       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

if [ "${SLIMMING}x" != 'truex' ] ; then
      chown -R "${GRID_USER}":oinstall "$GRID_BASE"
      chown -R "${GRID_USER}":oinstall "$GRID_HOME"
      mkdir -p "$INVENTORY"
      chown -R "${GRID_USER}":oinstall "$INVENTORY"
      # shellcheck disable=SC2129
      echo "export PATH=$GRID_PATH" >> /home/"${GRID_USER}"/.bashrc
      echo "export LD_LIBRARY_PATH=$GRID_LD_LIBRARY_PATH" >> /home/"${GRID_USER}"/.bashrc
      echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/"${GRID_USER}"/.bashrc
      echo "export GRID_HOME=$GRID_HOME" >> /home/"${GRID_USER}"/.bashrc
      echo "export GRID_BASE=$GRID_BASE" >> /home/"${GRID_USER}"/.bashrc
      echo "export DB_HOME=$DB_HOME" >> /home/"${GRID_USER}"/.bashrc
fi
