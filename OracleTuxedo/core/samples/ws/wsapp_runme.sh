#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Shell script to build and run wsapp.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Author: Todd Little
#
# Usage: source wsapp_runme.sh
#
mkdir -p /u01/oracle/user_projects
cd /u01/oracle/user_projects || return 1
rm -rf wsapp
mkdir wsapp
cd wsapp  || return 1

# Create environment setup script setenv.sh
HOSTNAME=$(uname -n)
APPDIR=$(pwd)
export HOSTNAME APPDIR

cat >setenv.sh << EndOfFile
source  ${TUXDIR}/tux.env
export HOSTNAME=${HOSTNAME}
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export TM_SECURITY_CONFIG=NONE
export TM_ALLOW_NOTLS=Y
export IPCKEY=112233
export NLSPORT=12233
export JMXPORT=22233
export WSNADDR="//${HOSTNAME}:9055"   # both server and client in same container or same k8s node
EndOfFile

# shellcheck disable=SC1091
source ./setenv.sh

# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -Rf clientws serverws tuxconfig ubbws ULOG.*

# Create the Tuxedo configuration file
cat >ubbws << EndOfFile
*RESOURCES
IPCKEY		$IPCKEY
DOMAINID	wsapp
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
		MAXWSCLIENTS=5

*GROUPS
APPGRP		LMID=site1 GRPNO=1 OPENINFO=NONE
WSGRP		LMID=site1 GRPNO=2 OPENINFO=NONE

*SERVERS
serverws	SRVGRP=APPGRP SRVID=1   CLOPT="-A"
WSL		SRVGRP=WSGRP  SRVID=10  CLOPT="-A -- -n ${WSNADDR} -m 2"
		RESTART=Y     MAXGEN=10 GRACE=3600


*SERVICES
BASICWS

EndOfFile

# Get the sources if not already in this directory
if [ ! -r clientws.c ]
    then
	cp /u01/oracle/clientws.c .
fi
if [ ! -r serverws.c ]
    then
	cp /u01/oracle/serverws.c .
fi

# Compile the configuration file and build the client and server
tmloadcf -y ubbws
buildclient -w -o clientws -f clientws.c
buildserver -o serverws -f serverws.c -s BASICWS
# Boot up the domain
tmboot -y
# Run the client
echo "Running clientws app now, if you see 'tpcall succeeded' below then app ran OK ..."
./clientws 
#cat ${APPDIR}/ULOG*
# Shutdown the domain
tmshutdown -y

