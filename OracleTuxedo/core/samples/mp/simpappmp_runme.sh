#!/bin/sh
#
# Shell script to run simpappmp.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.  It
# also assumes that simpappmp_build.sh was run during the image build.
#
# Author: Todd Little
#
# Usage: source simpappmp_runme.sh [TuxedoDirectory]
#
if [ ! -z "$1" ]
    then
	export TUXDIR=$1
elif [ -z "$TUXDIR" ]
    then
	export TUXDIR=~/tuxHome/tuxedo12.1.3.0.0
fi

cd /u01/oracle/simpappmp
# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -Rf tuxconfig ubbsimple ULOG.*

# Setup environment variables
source ./setenv.sh
export HOSTNAME=`hostname`

# Create the Tuxedo configuration file
cat >ubbsimplemp << EndOfFile
*RESOURCES
IPCKEY		$IPCKEY
DOMAINID	simpappmp
MASTER		site1
MAXACCESSERS	100
MAXSERVERS	50
MAXSERVICES	50
MODEL		MP
LDBAL		Y
OPTIONS		LAN,MIGRATE

*MACHINES
node1		LMID=site1
		APPDIR="$APPDIR"
		TUXCONFIG="$APPDIR/tuxconfig"
		TUXDIR="$TUXDIR"

node2		LMID=site2
		APPDIR="$APPDIR"
		TUXCONFIG="$APPDIR/tuxconfig"
		TUXDIR="$TUXDIR"

node3		LMID=site3
		APPDIR="$APPDIR"
		TUXCONFIG="$APPDIR/tuxconfig"
		TUXDIR="$TUXDIR"

*GROUPS
APPGRP1		LMID=site1,site2 GRPNO=1 OPENINFO=NONE
APPGRP2		LMID=site2,site3 GRPNO=2 OPENINFO=NONE
APPGRP3		LMID=site3,site1 GRPNO=3 OPENINFO=NONE

*NETWORK
site1	NADDR="//node1:3550" NLSADDR="//node1:3450"
site2	NADDR="//node2:3550" NLSADDR="//node2:3450"
site3	NADDR="//node3:3550" NLSADDR="//node3:3450"

*SERVERS
simpserv	SRVGRP=APPGRP1 SRVID=1 CLOPT="-A"
simpserv	SRVGRP=APPGRP2 SRVID=1 CLOPT="-A"
simpserv	SRVGRP=APPGRP3 SRVID=1 CLOPT="-A"

*SERVICES
TOUPPER
EndOfFile

# Compile the configuration file
tmloadcf -y ubbsimplemp

# Boot up the domain
tmboot -y
# Run the client
./simpcl "If you see this message, simpapp ran OK" &
./simpcl "If you see this message, simpapp ran OK" &
./simpcl "If you see this message, simpapp ran OK" &
./simpcl "If you see this message, simpapp ran OK" &
./simpcl "If you see this message, simpapp ran OK"

