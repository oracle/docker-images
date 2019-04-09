#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Install grid software inside the container.
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
if [ "$EDITION" != "EE" ]; then
   echo "ERROR: Wrong edition has been passed on!"
   echo "Edition $EDITION is no a valid edition!"
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
mkdir -p /home/grid/.ssh && \
chmod 700 /home/grid/.ssh && \
unzip -q $INSTALL_SCRIPTS/$INSTALL_FILE_1 -d $GRID_HOME    && \
#rm -f $INSTALL_SCRIPTS/$INSTALL_FILE_1 && \
$GRID_HOME/perl/bin/perl $GRID_HOME/clone/bin/clone.pl -silent ORACLE_BASE=$GRID_BASE ORACLE_HOME=$GRID_HOME OSDBA_GROUP=asmdba OSASM_GROUP=asmadmin  ORACLE_HOME_NAME="grid122_home1" INVENTORY_LOCATION=$INVENTORY  LOCAL_NODE="$temp_var1" CRS=TRUE

