#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Shell script to build and run simpapp.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Author: Todd Little
#
# Usage: source simpapp_runme.sh
#
cd /u01/oracle/user_projects
rm -rf simpapp
mkdir simpapp
cd simpapp

# Create environment setup script setenv.sh
export HOSTNAME=`uname -n`
export APPDIR=`pwd`

cat >setenv.sh << EndOfFile
source  ${TUXDIR}/tux.env
export HOSTNAME=${HOSTNAME}
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export TM_SECURITY_CONFIG=NONE
export IPCKEY=112233
export NLSPORT=12233
export JMXPORT=22233
EndOfFile
source ./setenv.sh

# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -Rf simpcl simpserv tuxconfig ubbsimple ULOG.*

# Create the Tuxedo configuration file
cat >ubbsimple << EndOfFile
*RESOURCES
IPCKEY		$IPCKEY
DOMAINID	simpapp
MASTER		site1
MAXACCESSERS	50
MAXSERVERS	20
MAXSERVICES	10
MODEL		SHM
LDBAL		Y

*MACHINES
"$HOSTNAME"	LMID=site1
		APPDIR="$APPDIR"
		TUXCONFIG="$APPDIR/tuxconfig"
		TUXDIR="$TUXDIR"

*GROUPS
APPGRP		LMID=site1 GRPNO=1 OPENINFO=NONE

*SERVERS
simpserv	SRVGRP=APPGRP SRVID=1 CLOPT="-A"

*SERVICES
TOUPPER

EndOfFile

# Get the sources if not already in this directory
if [ ! -r simpcl.c ]
    then
	cp $TUXDIR/samples/atmi/simpapp/simpcl.c .
fi
if [ ! -r simpserv.c ]
    then
	cp $TUXDIR/samples/atmi/simpapp/simpserv.c .
fi

# Compile the configuration file and build the client and server
tmloadcf -y ubbsimple
buildclient -o simpcl -f simpcl.c
buildserver -o simpserv -f simpserv.c -s TOUPPER
# Boot up the domain
tmboot -y
# Run the client
./simpcl "If you see this message, simpapp ran OK"
# Shutdown the domain
tmshutdown -y

