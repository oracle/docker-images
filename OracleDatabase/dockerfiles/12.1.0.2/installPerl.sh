#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Installs new Perl binaries if not present
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Install latest Perl

# Exit immediately if any command exits non-zero
set -e

cd $INSTALL_DIR
mv $ORACLE_HOME/perl $ORACLE_HOME/perl.old
curl -o perl.tar.gz http://www.cpan.org/src/5.0/perl-5.14.1.tar.gz
tar -xzf perl.tar.gz
cd perl-*
./Configure -des -Dprefix=$ORACLE_HOME/perl -Doptimize=-O3 -Dusethreads -Duseithreads -Duserelocatableinc
make clean
make
make install

# Copy old binaries into new Perl dir
cd $ORACLE_HOME/perl
rm -rf lib/ man/
cp -r ../perl.old/lib/ .
cp -r ../perl.old/man/ .
cp ../perl.old/bin/dbilogstrip bin/
cp ../perl.old/bin/dbiprof bin/
cp ../perl.old/bin/dbiproxy bin/
cp ../perl.old/bin/ora_explain bin/
cd $ORACLE_HOME/lib
ln -sf ../javavm/jdk/jdk7/lib/libjavavm12.a

# Relink Oracle
cd $ORACLE_HOME/bin
if ! relink all; then
	echo "Relink all failed"
	cat "$ORACLE_HOME/install/relink.log"
	exit 1
fi

# Cleanup
rm -rf $ORACLE_HOME/perl.old
rm -rf $INSTALL_DIR/perl-*
