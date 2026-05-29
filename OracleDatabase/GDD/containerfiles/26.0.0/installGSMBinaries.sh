#!/bin/bash
#
# LICENSE UPL 1.0
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# shellcheck disable=SC1143
# shellcheck disable=SC2164

export ORACLE_BASE=$GSM_BASE
export ORACLE_HOME=$GSM_HOME

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

sed -i -e "s|###INVENTORY###|$INVENTORY|g" $INSTALL_SCRIPTS/$INSTALL_RSP && \
sed -i -e "s|###ORACLE_BASE###|$GSM_BASE|g" $INSTALL_SCRIPTS/$INSTALL_RSP && \
sed -i -e "s|###ORACLE_HOME###|$GSM_HOME|g" $INSTALL_SCRIPTS/$INSTALL_RSP

# Install Oracle binaries
#cd $INSTALL_SCRIPTS  && \
#unzip $INSTALL_FILE_1 && \
#rm $INSTALL_FILE_1    && \

unzip $INSTALL_SCRIPTS/$INSTALL_FILE_1 -d $ORACLE_HOME && \
rm $INSTALL_SCRIPTS/$INSTALL_FILE_1 && \
$ORACLE_HOME/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_SCRIPTS/$INSTALL_RSP -ignorePrereqFailure || true && \
#rm -rf gsm && \
cd $HOME
