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
#	p19927652_121300_Linux-x86-64.zip	- Tuxedo lastest patch kit from Oracle - RP011
#						  actual file name may be different
#
# Usage:  sh tuxedo12.1.3_silent_install.sh [patch-filename [tuxedo-installer-filename]]
#	patch-filename defaults to the latest patch file in the current directory
#	tuxedo-installer-filename defaults to tuxedo121300_64_Linux_01_x86.zip
#
# Created by Todd Little  1-Dec-2014
#
# Get the arguments
#set -x
CURDIR=`pwd`
INSTALLER=tuxedo121300_64_Linux_01_x86.zip
PATCH=`ls p*_121300_Linux-x86-64.zip`
if [ ! -z "$1" ]
    then
	PATCH=$1
	if [ ! -z "$2" ]
	    then
		INSTALLER=$2
	fi
fi
echo "Using patch file $PATCH"
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
#
# Install rolling patch
if [ -e $PATCH ]
    then
	echo "Starting patch"
	export ORACLE_HOME=/home/oracle/tuxHome
	unzip -qq /home/oracle/Downloads/$PATCH
	rm -Rf /home/oracle/Downloads/$PATCH
	$ORACLE_HOME/OPatch/opatch apply -invPtrLoc /home/oracle/Downloads/oraInst.loc *.zip
fi



