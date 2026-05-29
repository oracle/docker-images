#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2019
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Applies all patches to the Oracle Home
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Make sure Oracle perl binary is in PATH
# shellcheck disable=SC1090
# shellcheck disable=SC2164
# shellcheck disable=SC2144
# shellcheck disable=SC2045
# shellcheck disable=SC2010



source /home/${GSM_USER}/.bashrc

PATH=$GSM_HOME/perl/bin:$GSM_HOME/OPatch:$PATH

# Patch database binaries with patch sets
cd $PATCH_INSTALL_DIR/opatch

#  If exists, install newer OPatch version if present
if [ -f p6880880*.zip ]; then
   # Unzip and remove zip file
   unzip p6880880*.zip
   #rm p6880880*.zip
   # Remove old OPatch folder
   rm -rf $GSM_HOME/OPatch
   # Move new OPatch folder into GSM_HOME
   mv OPatch $GSM_HOME/
fi;

cd $PATCH_INSTALL_DIR/${GSM_USER}

# Loop over all directories (001, 002, 003, ...)
for file in `ls -d */`; do
   # Go into sub directory (cd 001)
   cd $file;
   if [ -f *.zip ]; then

   # Unzip the actual patch (unzip pNNNNNNN.zip)
   unzip -o *.zip;
   # Go into patch directory (cd NNNNNNN)
   PATCH_DIR=`ls -l | grep ^d | awk '{ print $9 }'`
   PATCH_DIR_COUNT=`ls -l | grep ^d | awk '{ print $9 }'| wc -l`
   if [ ${PATCH_DIR_COUNT} -gt 1 ]; then
    echo " More than one patch zip file is copied in $file! Failed. Please copy one patch file under $file"
    exit 1
   fi
   if [ ! -d ${PATCH_DIR} ]; then
    echo "PATCH dir doesn't exist. Failed!"
    exit 1
   fi

  # Applying patch
  $GSM_HOME/OPatch/opatchauto apply $PATCH_INSTALL_DIR/$GSM_USER/$file/$PATCH_DIR -binary -oh $GSM_HOME
  if [ $? -ne 0 ]; then
   exit 1
  fi

  fi
  cd ../
done;

cd $HOME
