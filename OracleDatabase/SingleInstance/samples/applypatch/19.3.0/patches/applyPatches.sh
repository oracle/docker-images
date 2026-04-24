#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2017
# Author: gerald.venzl@oracle.com
# Description: Applies all patches to the Oracle Home
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Make sure Oracle perl binary is in PATH
PATH=$ORACLE_HOME/perl/bin:$PATH

# Patch database binaries with patch sets
cd $PATCH_INSTALL_DIR/

# If present, install a newer OPatch release first
if ls p6880880*.zip >/dev/null 2>&1; then
   unzip p6880880*.zip
   rm p6880880*.zip
   rm -rf $ORACLE_HOME/OPatch
   mv OPatch $ORACLE_HOME/
fi

# Loop over all directories (001, 002, 003, ...)
for file in `ls -d */`; do
   cd $file
   unzip -o *.zip
   cd */
   opatch apply -silent
   return_code=$?
   if [ "$return_code" != "0" ]; then
      exit $return_code
   fi
   cd ../
   rm -rf */
   rm -f *.xml
   cd ../
done

cd $HOME

rm -rf $PATCH_INSTALL_DIR
