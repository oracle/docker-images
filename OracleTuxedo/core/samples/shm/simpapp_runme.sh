#!/bin/sh
#
# Shell script to build and run simpapp.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Author: Todd Little
#
# Usage: source simpapp_runme.sh [TuxedoVersion]
#        TuxedoVersion: 12.1.3 or 12.2.2, 12.2.2 by default
#
cd /u01/oracle/user_projects
rm -rf simpapp
mkdir simpapp
cd simpapp
if [ ! -z "$1" ]
    then
  if [ "$1" = "12.1.3" ]
  then
	export TUXDIR=~/tuxHome/tuxedo12.1.3.0.0
  else
	export TUXDIR=~/tuxHome/tuxedo12.2.2.0.0
  fi
elif [ -z "$TUXDIR" ]
    then
	export TUXDIR=~/tuxHome/tuxedo12.2.2.0.0
fi

# Create environment setup script setenv.sh
export HOSTNAME=`uname -n`
export APPDIR=`pwd`

cat >setenv.sh << EndOfFile
source  ${TUXDIR}/tux.env
export HOSTNAME=${HOSTNAME}
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export IPCKEY=112233
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

/bin/bash
