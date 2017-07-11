#!/bin/sh
#
# Shell script to build simpappmp.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Author: Todd Little
#
# Usage: source simpappmp_build.sh [TuxedoDirectory]
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
rm -Rf simpcl simpserv tuxconfig ubbsimple ULOG.*

# Create environment setup script setenv.sh
export APPDIR=`pwd`
cat >setenv.sh << EndOfFile
source  ${TUXDIR}/tux.env
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export IPCKEY=112233
EndOfFile
source ./setenv.sh

# Get the sources if not already in this directory
if [ ! -r simpcl.c ]
    then
	cp $TUXDIR/samples/atmi/simpapp/simpcl.c .
fi
if [ ! -r simpserv.c ]
    then
	cp $TUXDIR/samples/atmi/simpapp/simpserv.c .
fi

# Build the client and server
buildclient -o simpcl -f simpcl.c
buildserver -o simpserv -f simpserv.c -s TOUPPER


