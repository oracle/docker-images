#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2019
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Applies all patches to the Oracle Home
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Make sure Oracle perl binary is in PATH
source /home/${GRID_USER}/.bashrc

PATH=$GRID_HOME/perl/bin:$GRID_HOME/OPatch:$PATH

# Patch database binaries with patch sets
cd $PATCH_INSTALL_DIR/opatch

#  If exists, install newer OPatch version if present
if [ -f p6880880*.zip ]; then
   # Unzip and remove zip file
   unzip p6880880*.zip
#   rm p6880880*.zip
   # Remove old OPatch folder
   rm -rf $GRID_HOME/OPatch
   # Move new OPatch folder into GRID_HOME
   mv OPatch $GRID_HOME/
fi;

cd $PATCH_INSTALL_DIR/${GRID_USER}

# Loop over all directories (001, 002, 003, ...)
for file in `ls -d */`; do
   # Go into sub directory (cd 001)
   cd $file;
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
   # Analyzing the patch 
   sudo -E $GRID_HOME/OPatch/opatchauto apply $PATCH_INSTALL_DIR/$GRID_USER/$file/$PATCH_DIR -oh $GRID_HOME -analyze
   if [ $? -ne 0 ]; then
     exit 1
   fi

   # Applying patch
   sudo -E $GRID_HOME/OPatch/opatchauto apply $PATCH_INSTALL_DIR/$GRID_USER/$file/$PATCH_DIR -oh $GRID_HOME 
   if [ $? -ne 0 ]; then
     exit 1
   fi


   cd ../
   # Clean up patch directory (-f needed because some files 
   # in patch directory may not have write permissions)
   # Delete any xml artifacts if present.
   # Go back into root directory
   cd ../
done;

cd $HOME
