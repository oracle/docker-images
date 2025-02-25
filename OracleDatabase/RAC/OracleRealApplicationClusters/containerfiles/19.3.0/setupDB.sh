#!/bin/bash
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

# Create Directories
if [ "${SLIMMING}x" != 'truex' ]; then
   mkdir -p "$DB_BASE"
   mkdir -p "$DB_HOME"
fi

usermod -g oinstall -G oinstall,dba,oper,backupdba,dgdba,kmdba,asmdba,asmoper,racdba,asmadmin "${DB_USER}"

chmod 775 "$INSTALL_SCRIPTS"


if [ "${SLIMMING}x" != 'truex' ]; then
 chown -R "${DB_USER}":oinstall "$DB_BASE"
 chown -R "${DB_USER}":oinstall "$DB_HOME"
 chown -R "${DB_USER}":oinstall "$INSTALL_SCRIPTS"
 echo "export PATH=$DB_PATH" >> /home/"${DB_USER}"/.bashrc
 echo "export LD_LIBRARY_PATH=$DB_LD_LIBRARY_PATH" >> /home/"${DB_USER}"/.bashrc
 echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/"${DB_USER}"/.bashrc
 echo "export GRID_HOME=$GRID_HOME" >> /home/"${DB_USER}"/.bashrc
 echo "export DB_BASE=$DB_BASE" >> /home/"${DB_USER}"/.bashrc
 echo "export DB_HOME=$DB_HOME" >> /home/"${DB_USER}"/.bashrc
fi

if [ "${SLIMMING}x" != 'truex' ]; then
 if [ "${DB_USER}" == "${GRID_USER}" ]; then
   sed -i '/PATH=/d' /home/"${DB_USER}"/.bashrc
   echo "export PATH=$GRID_HOME/bin:$DB_PATH" >> /home/"${DB_USER}"/.bashrc 
   echo "export LD_LIBRARY_PATH=$GRID_HOME/lib:$DB_LD_LIBRARY_PATH" >> /home/"${DB_USER}"/.bashrc
 fi
fi
