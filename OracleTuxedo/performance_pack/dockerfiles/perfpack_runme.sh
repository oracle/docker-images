#!/bin/sh
#
# Shell script to build and run perfpack.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Author: Judy Liu
#
# Usage: source perfpack_runme.sh
#
cd /u01/oracle/user_projects
rm -rf perfpack
mkdir perfpack
cd perfpack

# Create environment setup script setenv.sh
export HOSTNAME=`uname -n`
export APPDIR=`pwd`

cat <<EOF
All of the features in Tuxedo Advanced Performance Pack are enabled 
if the OPTIONS parameter in RESOURES in UBBCONFIG is set to XPP. 
    OPTIONS	        XPP
And each of these features can be individually disabled if needed:
    OPTIONS        NO_AA,XPP,NO_RDONLY1PC,NO_SHMQ
    RMOPTIONS      NO_XAAFFINITY,SINGLETON,NO_FAN,NO_COMMONXID

EOF

cat >setenv.sh << EndOfFile
source  ${TUXDIR}/tux.env
export HOSTNAME=${HOSTNAME}
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export IPCKEY=112235
EndOfFile
source ./setenv.sh

# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -Rf simpcl simpserv tuxconfig ubbsimple ULOG.*

# Create the Tuxedo configuration file
cat >ubbsimple << EndOfFile
*RESOURCES
IPCKEY		$IPCKEY
DOMAINID	perfpack
MASTER		site1
MAXACCESSERS	150
MAXSERVERS	50
MAXSERVICES	100
MODEL		SHM
LDBAL		Y
#All of the features in Tuxedo Advanced Performance Pack are enabled 
# if the OPTIONS parameter in RESOURES in UBBCONFIG is set to XPP. 
OPTIONS	        XPP
#Each of these features can be individually disabled if needed:
#OPTIONS        NO_AA,XPP,NO_RDONLY1PC,NO_SHMQ
#RMOPTIONS      NO_XAAFFINITY,SINGLETON,NO_FAN,NO_COMMONXID


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
echo "Build tuxedo configuration file..."
tmloadcf -y ubbsimple
echo "Build tuxedo client..."
buildclient -o simpcl -f simpcl.c
echo "Build tuxedo server..."
buildserver -o simpserv -f simpserv.c -s TOUPPER
# Boot up the domain
echo "Boot up the domain..."
tmboot -y
# Run the client
echo "Run the client..."
./simpcl "If you see this message, perfpack ran OK"
# Shutdown the domain
echo "Shutdown the domain..."
tmshutdown -y

