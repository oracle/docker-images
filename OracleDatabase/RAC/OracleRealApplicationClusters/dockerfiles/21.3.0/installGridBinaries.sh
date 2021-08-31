#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2021 Oracle and/or its affiliates.
#
# Since: December, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Install grid software inside the container.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

EDITION=$1
PATCH_NUMBER=$2

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

# Replace place holders
# ---------------------
sed -i -e "s|###HOSTNAME###|$temp_var1|g" $INSTALL_SCRIPTS/$GRID_SW_INSTALL_RSP && \
sed -i -e "s|###INSTALL_TYPE###|CRS_SWONLY|g" $INSTALL_SCRIPTS/$GRID_SW_INSTALL_RSP && \
sed -i -e "s|###GRID_BASE###|$GRID_BASE|g" $INSTALL_SCRIPTS/$GRID_SW_INSTALL_RSP && \
sed -i -e "s|###INVENTORY###|$INVENTORY|g" $INSTALL_SCRIPTS/$GRID_SW_INSTALL_RSP

# Install Oracle binaries
mkdir -p /home/grid/.ssh && \
chmod 700 /home/grid/.ssh && \
unzip -q $INSTALL_SCRIPTS/$INSTALL_FILE_1 -d $GRID_HOME && \
$GRID_HOME/gridSetup.sh -silent -responseFile $INSTALL_SCRIPTS/$GRID_SW_INSTALL_RSP -ignorePrereqFailure || true
