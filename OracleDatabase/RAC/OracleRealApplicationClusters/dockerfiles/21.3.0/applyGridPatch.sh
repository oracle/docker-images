#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2021 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Apply Patch for Oracle Grid and Databas.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

PATCH=$1

# Check whether edition has been passed on
if [ "PATCH" == "" ]; then
   echo "ERROR: No Patch  has been passed on!"
   echo "Please specify the correct PATCH!"
   exit 1;
fi;

# Check whether GRID_BASE is set
if [ "$GRID_BASE" == "" ]; then
   echo "ERROR: GRID_BASE has not been set!"
   echo "You have to have the GRID_BASE environment variable set to a valid value!"
   exit 1;
fi;

# Check whether GRID_HOME is set
if [ "$GRID_HOME" == "" ]; then
   echo "ERROR: GRID_HOME has not been set!"
   echo "You have to have the GRID_HOME environment variable set to a valid value!"
   exit 1;
fi;

temp_var1=`hostname`
# Install Oracle binaries

unzip -q $INSTALL_SCRIPTS/$PATCH -d $GRID_USER_HOME  && \
rm -f $INSTALL_SCRIPTS/$GRID_PATCH && \
cd $GRID_USER_HOME/$PATCH_NUMBER/$PATCH_NUMBER && \
$GRID_HOME/OPatch/opatch napply -silent -local -oh $GRID_HOME -id $PATCH_NUMBER && \
cd $GRID_USER_HOME && \
rm -rf $GRID_USER_HOME/$PATCH_NUMBER
