#!/bin/sh
#
# Script file for tuxedo12.2.2 silent mode install
#
# This procedure assumes that the following files are in the current directory:
#	install.sh            - This file
#	tuxedo12.2.2.rsp      - Silent install response file
#
#   and that these files can be found in the in /home/oracle/Downloads
#	tuxedo122200_64_Linux_01_x86.zip	- Tuxedo installation kit from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#						  
#
# Usage:  sh install.sh [tuxedo-installer-filename]
#	by default, tuxedo-installer-filename is tuxedo122200_64_Linux_01_x86.zip
#
# Created by Judy Liu
#
# Get the arguments
#set -x
CURDIR=`pwd`
INSTALLER=tuxedo122200_64_Linux_01_x86.zip
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
# TUXDIR is /home/oracle/tuxHome/tuxedo12.2.2.0.0
#
JAVA_HOME=/usr/java/default ./Disk1/install/runInstaller.sh -invPtrLoc /home/oracle/Downloads/oraInst.loc -responseFile $CURDIR/tuxedo12.2.2.rsp -silent -waitforcompletion
#
# Remove the installer and generated response file
rm -Rf Disk1 tuxedo12.2.2.rsp $INSTALLER
echo "Tuxedo installation done"

