#!/bin/sh
#
# Script file for Tuxedo Message Queue silent install mode
#
# This procedure assumes that the following files are in the current directory:
#	install.sh            - This file
#	tuxedotmq12.1.3.rsp   - Silent install response file
#
#   and that these files can be found in the in /home/oracle/Downloads
#	otmq121300_64_Linux_x86.zip	- installation kit from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#
# Usage:  sh ./install.sh [installer-filename]
#	by default, installer-filename is otmq121300_64_Linux_x86.zip
#
# Created by Judy Liu
#
# Get the arguments
#set -x
CURDIR=`pwd`
INSTALLER=otmq121300_64_Linux_x86.zip

if [ ! -z "$1" ]
    then
	INSTALLER=$1
fi
if [ ! -z "$2" ]
    then
	RPFILE=$2
fi
echo "Using Tuxedo otmq installer $INSTALLER"
# Unzip the downloaded installation kit to the current directory
cd /home/oracle/Downloads
unzip -qq /home/oracle/Downloads/$INSTALLER
# Run the installer in silent mode
# 
# Need to create oraInst.loc first:
echo "inventory_loc=/home/oracle/oraInventory" > /home/oracle/Downloads/oraInst.loc
echo "inst_group=oracle" >> /home/oracle/Downloads/oraInst.loc

#JAVA_HOME=/usr/java/default ORACLE_HOME=/home/oracle/tuxHome /home/oracle/tuxHome/OPatch/opatch apply $CURDIR/$RPFILE -invPtrLoc $CURDIR/oraInst.loc

#
# Installs all of Tuxedo otmq including samples.
# Tuxedo home is /home/oracle/tuxHome
#
./Disk1/install/runInstaller -invPtrLoc /home/oracle/Downloads/oraInst.loc -responseFile $CURDIR/tuxedotmq12.1.3.rsp -silent -waitforcompletion
#
# Remove the installer and generated response file
rm -Rf Disk1 tuxedotmq12.1.3.rsp $INSTALLER
echo "Tuxedo otmq installation done"

