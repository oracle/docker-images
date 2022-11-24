#!/bin/bash

cd /u01/data/bankapp/

APPDIR=$(pwd)
export APPDIR

UNAME1=$(uname -n)
TUX_UID=$(id -u)
TUX_GID=$(id -g)


# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -f TLOG GWTLOG tuxconfig saltconfig bankdl1 bankdl2 bankdl3 ULOG.*



# modify and run the environment setup script 
cp -p bankvar bankvar.new

echo '
#
# For GWWS
#
GWTLOGDEVICE=${APPDIR}/GWTLOG
export GWTLOGDEVICE
#
# Device for binary file that gives SALT all its information
#
SALTCONFIG=${APPDIR}/saltconfig
export SALTCONFIG
' >> bankvar.new

source ./bankvar.new


# Modify the Tuxedo configuration file
sed -e "s;<TUXDIR1>;${TUXDIR};g" \
    -e "s;<APPDIR1>;${APPDIR};g" \
    -e "s;<user id from id(1)>;${TUX_UID};g" \
    -e "s;<group id from id(1)>;${TUX_GID};g" \
    -e "s;<SITE1's uname>;\"${UNAME1}\";g" \
    -e "s;^MAXACCESSERS\(\s\+\).*$;MAXACCESSERS\1100;g" \
    -e "s;^MAXSERVERS\(\s\+\).*$;MAXSERVERS\1100;g" \
    -e "s;^MAXSERVICES\(\s\+\).*$;MAXSERVICES\1500;g" \
    -e "s;^\(\s*\)\(ULOGPFX=.*\);\1\2\n\1MAXWSCLIENTS=15;g" \
    -e 's;\(bankdl3:bankdb:readwrite".*$\);\1\nGWWSGRP		GRPNO=4\n	OPENINFO=""	TMSNAME=""	LMID=SITE1;g' \
    -e 's;\(BALC\s\+SRVGRP=BANKB3\s\+SRVID=29.*$\);\1\
TMMETADATA  SRVGRP=GWWSGRP      SRVID=1     CLOPT="-A -- -f bankapp.repos"\
GWWS        SRVGRP=GWWSGRP      SRVID=2     CLOPT="-A -- -iGWWSRestful";g' \
   ubbshm > UBBSHM


# Create ENVFILE
export MASKPATH=${APPDIR}
./envfile


# Modify bankapp.dep
sed -e "s;<APPDIR1>;${APPDIR};g" bankapp.dep > BANKAPP.DEP


# Compile the configuration file 
tmloadcf -y UBBSHM
wsloadcf -y BANKAPP.DEP


# Create the bank DB and the logs
./crbank
./crtlog

 
# Boot up the domain
tmboot -y


# Insert sample records into the bank DB
./populate


# Sleep
sleep infinity

