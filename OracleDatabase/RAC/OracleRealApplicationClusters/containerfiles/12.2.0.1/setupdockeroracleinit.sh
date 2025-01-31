#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description:  Setup Shared Library requirement for dockeroracleinit
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

#Creating Dir under $GRID_HOME for dockeroracleinit to access required libs
mkdir -p $GRID_HOME/dockeroracleinit/lib/

ln -s  $GRID_HOME/lib/libhasgen12.so     $GRID_HOME/dockeroracleinit/lib/libhasgen12.so
ln -s  $GRID_HOME/lib/libocr12.so        $GRID_HOME/dockeroracleinit/lib/libocr12.so
ln -s  $GRID_HOME/lib/libocrb12.so       $GRID_HOME/dockeroracleinit/lib/libocrb12.so
ln -s  $GRID_HOME/lib/libocrutl12.so     $GRID_HOME/dockeroracleinit/lib/libocrutl12.so
ln -s  $GRID_HOME/lib/libclntsh.so       $GRID_HOME/dockeroracleinit/lib/libclntsh.so 
ln -s  $GRID_HOME/lib/libclntshcore.so   $GRID_HOME/dockeroracleinit/lib/libclntshcore.so
ln -s  $GRID_HOME/lib/libskgxn2.so       $GRID_HOME/dockeroracleinit/lib/libskgxn2.so
ln -s  $GRID_HOME/lib/libasmclntsh12.so  $GRID_HOME/dockeroracleinit/lib/libasmclntsh12.so
ln -s  $GRID_HOME/lib/libcell12.so       $GRID_HOME/dockeroracleinit/lib/libcell12.so
ln -s  $GRID_HOME/lib/libskgxp12.so      $GRID_HOME/dockeroracleinit/lib/libskgxp12.so  
ln -s  $GRID_HOME/lib/libnnz12.so        $GRID_HOME/dockeroracleinit/lib/libnnz12.so
ln -s  $GRID_HOME/lib/libmql1.so         $GRID_HOME/dockeroracleinit/lib/libmql1.so
ln -s  $GRID_HOME/lib/libipc1.so         $GRID_HOME/dockeroracleinit/lib/libipc1.so
ln -s  $GRID_HOME/lib/libons.so          $GRID_HOME/dockeroracleinit/lib/libons.so
ln -s  $GRID_HOME/lib/libclntsh.so.12.1  $GRID_HOME/dockeroracleinit/lib/libclntsh.so.12.1
ln -s  $GRID_HOME/lib/libclntshcore.so.12.1 $GRID_HOME/dockeroracleinit/lib/libclntshcore.so.12.1
