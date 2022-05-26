#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Convert $1 into upper case via "^^" (bash version 4 onwards)
EDITION=${1^^}

# Check whether edition has been passed on
if [ "$EDITION" == "" ]; then
   echo "ERROR: No edition has been passed on!"
   echo "Please specify the correct edition!"
   exit 1;
fi;

# Check whether correct edition has been passed on
if [ "$EDITION" != "EE" ] && [ "$EDITION" != "SE2" ]; then
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
sed -i -e "s|###ORACLE_EDITION###|$EDITION|g" "$INSTALL_DIR"/"$INSTALL_RSP" && \
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" "$INSTALL_DIR"/"$INSTALL_RSP" && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" "$INSTALL_DIR"/"$INSTALL_RSP"

# Install Oracle binaries
cd "$ORACLE_HOME"       && \
mv "$INSTALL_DIR"/"$INSTALL_FILE_1" "$ORACLE_HOME"/ && \
unzip "$INSTALL_FILE_1" && \
rm "$INSTALL_FILE_1"    && \
"$ORACLE_HOME"/runInstaller -silent -force -waitforcompletion -responsefile "$INSTALL_DIR"/"$INSTALL_RSP" -ignorePrereqFailure && \
cd "$HOME"

if $SLIMMING; then
    # Remove not needed components
    # APEX
    rm -rf "$ORACLE_HOME"/apex && \
    # ORDS
    rm -rf "$ORACLE_HOME"/ords && \
    # SQL Developer
    rm -rf "$ORACLE_HOME"/sqldeveloper && \
    # UCP connection pool
    rm -rf "$ORACLE_HOME"/ucp && \
    # All installer files
    rm -rf "$ORACLE_HOME"/lib/*.zip && \
    # OUI backup
    rm -rf "$ORACLE_HOME"/inventory/backup/* && \
    # Network tools help
    rm -rf "$ORACLE_HOME"/network/tools/help && \
    # Database upgrade assistant
    rm -rf "$ORACLE_HOME"/assistants/dbua && \
    # Database migration assistant
    rm -rf "$ORACLE_HOME"/dmu && \
    # Remove pilot workflow installer
    rm -rf "$ORACLE_HOME"/install/pilot && \
    # Support tools
    rm -rf "$ORACLE_HOME"/suptools && \
    # Temp location
    rm -rf /tmp/* && \
    # Database files directory
    rm -rf "$INSTALL_DIR"/database
fi
