#!/bin/sh
#
# Script file for Tuxedo RP installer
#
# This procedure assumes that the following files are in the current directory:
#	install_tuxedorp.sh        		- This file
#
#   and that these files can be found in the in /home/oracle/Downloads
#	p24444780_122200_Linux-x86-64.zip	- Tuxedo RP installer from Oracle
#
# Get the arguments
#set -x
CURDIR=`pwd`
INSTALLER=$1
echo "Using Tuxedo RP installer $INSTALLER"
PATCHDIR=patch
PATCHFILE=
echo "Installing Tuxedo RP"
unzip $INSTALLER -d $PATCHDIR
ZIPFILES=`find $PATCHDIR -type f -iname '*.zip'`
for PATCHFILE in $ZIPFILES; do :; done
# Need to create oraInst.loc first:
echo "inventory_loc=/home/oracle/oraInventory" > /home/oracle/Downloads/oraInst.loc
echo "inst_group=oracle" >> /home/oracle/Downloads/oraInst.loc
/home/oracle/tuxHome/OPatch/opatch apply $CURDIR/$PATCHFILE -invPtrLoc /home/oracle/tuxHome/oraInst.loc
# Remove the installer and generated response file
rm -Rf $PATCHDIR $INSTALLER
echo "Tuxedo RP installation done"
