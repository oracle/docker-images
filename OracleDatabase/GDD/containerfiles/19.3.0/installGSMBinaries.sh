#!/bin/bash
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# MAINTAINER <paramdeep.saini@oracle.com>
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
cd $INSTALL_SCRIPTS  && \
unzip $INSTALL_FILE_1 && \
rm $INSTALL_FILE_1    && \
$INSTALL_SCRIPTS/gsm/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_SCRIPTS/$INSTALL_RSP -ignorePrereqFailure || true && \
rm -rf gsm && \
cd $HOME
