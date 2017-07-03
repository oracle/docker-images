#!/bin/sh
#
# Script file for tuxedo12.1.3 silent install mode
#
# This procedure assumes that the following files are in the current directory:
#	tuxedo12.1.3_silent_install.sh		- This file
#	tuxedo12.1.3.rsp			- Silent install response file
#
#   and that these files can be found in the in /home/oracle/Downloads
#	tuxedo121300_64_Linux_01_x86.zip	- Tuxedo installation kit from Oracle
#
# Usage:  sh tuxedo12.1.3_silent_install.sh [tuxedo-installer-filename]
#	tuxedo-installer-filename defaults to tuxedo121300_64_Linux_01_x86.zip
#
# Created by Todd Little  1-Dec-2014
#
# Get the arguments
#set -x
CURDIR=`pwd`
INSTALLER=tuxedo121300_64_Linux_01_x86.zip
if [ ! -z "$1" ]
    then
	INSTALLER=$1
fi
echo "Using Tuxedo installer $INSTALLER"
# Unzip the downloaded installation kit to the current directory
cd /home/oracle/Downloads
unzip -qq /home/oracle/Downloads/$INSTALLER
# Run the installer in silent mode
# 
# Need to create oraInst.loc first:
echo "inventory_loc=/home/oracle/oraInventory" > /home/oracle/Downloads/oraInst.loc
echo "inst_group=oracle" >> /home/oracle/Downloads/oraInst.loc
#
# Installs all of Tuxedo including samples without LDAP support.
# Tuxedo home is /home/oracle/tuxHome
# TUXDIR is /home/oracle/tuxHome/tuxedo12.1.3.0.0
#
./Disk1/install/runInstaller -invPtrLoc /home/oracle/Downloads/oraInst.loc -responseFile $CURDIR/tuxedo12.1.3.rsp -silent -waitforcompletion
#
# Remove the installer and generated response file
rm -Rf Disk1 tuxedo12.1.3.rsp $INSTALLER
echo "Tuxedo installation done"



