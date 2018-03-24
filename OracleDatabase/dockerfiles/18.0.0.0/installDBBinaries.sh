#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

EDITION=$1

# Check whether edition has been passed on
if [ "$EDITION" == "" ]; then
   echo "ERROR: No edition has been passed on!"
   echo "Please specify the correct edition!"
   exit 1;
fi;

# Check whether correct edition has been passed on
if [ "$EDITION" != "EE" -a "$EDITION" != "SE2" ]; then
   echo "ERROR: Wrong edition has been passed on!"
   echo "Edition $EDITION is no a valid edition!"
   exit 1;
fi;

# Check whether ORACLE_BASE is set
if [ "$ORACLE_BASE" == "" ]; then
   echo "ERROR: ORACLE_BASE has not been set!"
   echo "You have to have the ORACLE_BASE environment variable set to a valid value!"
   exit 1;
fi;

# Check whether ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
   echo "ERROR: ORACLE_HOME has not been set!"
   echo "You have to have the ORACLE_HOME environment variable set to a valid value!"
   exit 1;
fi;


# Replace place holders
# ---------------------
sed -i -e "s|###ORACLE_EDITION###|$EDITION|g" $INSTALL_DIR/$INSTALL_RSP && \
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" $INSTALL_DIR/$INSTALL_RSP && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" $INSTALL_DIR/$INSTALL_RSP

# Install Oracle binaries
cd $INSTALL_DIR       && \
unzip -q $INSTALL_FILE_1 -d $ORACLE_HOME && \
rm $INSTALL_FILE_1    && \
cd $HOME

# Remove not needed components
rm -rf $ORACLE_HOME/apex && \
rm -rf $ORACLE_HOME/jdbc && \
# ZDLRA installer files
rm -rf $ORACLE_HOME/lib/ra*.zip && \
rm -rf $ORACLE_HOME/ords && \
rm -rf $ORACLE_HOME/sqldeveloper && \
rm -rf $ORACLE_HOME/ucp && \
# OUI backup
rm -rf $ORACLE_HOME/inventory/backup/* && \
# Network tools help
rm -rf $ORACLE_HOME/network/tools/help/mgr/help_* && \
# Temp location
rm -rf /tmp/* && \
# Database files directory
rm -rf $INSTALL_DIR/database

# Link password reset file to home directory
ln -s $ORACLE_BASE/$PWD_FILE $HOME/
