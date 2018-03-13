#!/bin/bash
#
# Shell script to build and run jolt.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Author: Judy Liu
#
# Usage: source jolt_runme.sh
#
cd /u01/oracle/user_projects
rm -rf jolt
cp -r /u01/oracle/jolt /u01/oracle/user_projects
cd jolt

# Create environment setup script setenv.sh
export HOSTNAME=`uname -n`
export APPDIR=`pwd`

# Get the sources if not already in this directory
if [ ! -r simpserv.c ]
    then
        cp $TUXDIR/samples/atmi/simpapp/simpserv.c .
fi

.  ${TUXDIR}/tux.env
export HOSTNAME=${HOSTNAME}
export JAVA_HOME=/usr/java/jdk1.8.0_131
export PATH=$JAVA_HOME/bin:$PATH
export  CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$TUXDIR/udataobj/jolt/jolt.jar:$TUXDIR/udataobj/jolt/joltadmin.jar
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export IPCKEY=112233

# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -Rf *.class jrepository  tuxconfig ubbjolt ULOG.*

# Create the Tuxedo configuration file
cat >ubbjolt << EndOfFile
*RESOURCES
IPCKEY		$IPCKEY
DOMAINID	jolt
MASTER		SITE1
MAXACCESSERS	500
MAXSERVERS	200
MAXSERVICES	100
MODEL		SHM
LDBAL		N

*MACHINES
"$HOSTNAME"	LMID=SITE1
		APPDIR="$APPDIR"
		TUXCONFIG="$APPDIR/tuxconfig"
		TUXDIR="$TUXDIR"
		MAXWSCLIENTS=5

*GROUPS
APPGRP  LMID=SITE1      GRPNO=1
WSGRP   LMID=SITE1      GRPNO=2
GRPJAV  LMID=SITE1  GRPNO=3


*SERVERS
DEFAULT:
        CLOPT="-A"
JSL SRVGRP=GRPJAV SRVID=4
    CLOPT="-A -- -n //${HOSTNAME}:1304 -m1 -M5 -x10 -T1"
JREPSVR   SRVGRP=GRPJAV SRVID=10
          CLOPT="-A -- -W -P $APPDIR/jrepository"

joltsvr      SRVGRP=APPGRP SRVID=4


*SERVICES
TOUPPER

EndOfFile

# Compile the configuration file and build the client and server
tmloadcf -y ubbjolt
sed -i "s:@HOSTNAME@:${HOSTNAME}:g" joltclient.java
#javac joltclient.java
echo "build your own joltclient here"
buildserver -o joltsvr -f simpserv.c -s TOUPPER
tmloadrepos -i service.rep jrepository
# Boot up the domain
tmboot -y
# Run the client
#java joltclient
echo "Run your joltclient here"
# Shutdown the domain
#tmshutdown -y

tail -f /dev/null
