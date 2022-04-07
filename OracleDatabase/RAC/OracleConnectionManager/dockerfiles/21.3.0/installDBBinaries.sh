#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Install Oracle Database Client for CMAN
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

# Check whether DB_BASE is set
if [ "$DB_BASE" == "" ]; then
   echo "ERROR: DB_BASE has not been set!"
   echo "You have to have the DB_BASE environment variable set to a valid value!"
   exit 1;
fi;

# Check whether DB_HOME is set
if [ "$DB_HOME" == "" ]; then
   echo "ERROR: DB_HOME has not been set!"
   echo "You have to have the DB_HOME environment variable set to a valid value!"
   exit 1;
fi;

# Replace place holders
# ---------------------
sed -i -e "s|###DB_BASE###|$DB_BASE|g" $INSTALL_SCRIPTS/$DB_INSTALL_RSP && \
sed -i -e "s|###DB_HOME###|$DB_HOME|g" $INSTALL_SCRIPTS/$DB_INSTALL_RSP && \
sed -i -e "s|###INVENTORY###|$INVENTORY|g" $INSTALL_SCRIPTS/$DB_INSTALL_RSP

# Install Oracle binaries
cd $INSTALL_SCRIPTS       && \
unzip $INSTALL_FILE_1 && \
rm -f $INSTALL_SCRIPTS/$INSTALL_FILE_1 && \
$INSTALL_SCRIPTS/client/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_SCRIPTS/$DB_INSTALL_RSP -ignoreprereq || true && \
rm -rf $INSTALL_SCRIPTS/client
