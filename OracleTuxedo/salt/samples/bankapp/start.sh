#!/bin/bash

# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

cd /u01/data/bankapp/ || return 1

APPDIR=$(pwd)
export APPDIR

UNAME1=$(uname -n)
TUX_UID=$(id -u)
TUX_GID=$(id -g)



# Get the bankapp sources and build it
cp -rp "${TUXDIR}"/samples/atmi/bankapp/*  "${APPDIR}/"
export LD_LIBRARY_PATH="${TUXDIR}/lib:$LD_LIBRARY_PATH"
make -f bankapp.mk TUXDIR="${TUXDIR}" APPDIR="${APPDIR}"


# modify and run the environment setup script 
cp -p bankvar bankvar.new


# shellcheck disable=SC2016
cat << 'EOF' >> bankvar.new
#
# For GWWS
#
GWTLOGDEVICE="${APPDIR}/GWTLOG"
export GWTLOGDEVICE
#
# Device for binary file that gives SALT all its information
#
SALTCONFIG="${APPDIR}/saltconfig"
export SALTCONFIG
#
# For graceful shutdown 
#
export SHUTDOWN_MARKER_FILE="${APPDIR}/shutdown.marker"
EOF


# shellcheck disable=SC1091
source ./bankvar.new


# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -f TLOG GWTLOG tuxconfig saltconfig bankdl1 bankdl2 bankdl3 ULOG.*
rm -f "${SHUTDOWN_MARKER_FILE}"


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
TMMETADATA  SRVGRP=GWWSGRP      SRVID=1     CLOPT="-A -- -f bankapp.repos" \
GWWS        SRVGRP=GWWSGRP      SRVID=2     CLOPT="-A -- -iGWWSRestful";g' \
   ubbshm > ubbshm.new


# Create ENVFILE
export MASKPATH=${APPDIR}
./envfile


# Modify bankapp.dep
sed -e "s;<APPDIR1>;${APPDIR};g" bankapp.dep > bankapp.dep.new


# Compile the configuration file 
tmloadcf -y ubbshm.new       || return 1
wsloadcf -y bankapp.dep.new  || return 1


# Create the bank DB and the logs
./crbank || return 1
./crtlog || return 1

 
# Boot up the domain
tmboot -y


# Insert sample records into the bank DB
./populate


# beginning section of logs to stdout
cat "${APPDIR}/ULOG*"


# Sleep till shutdown initiated
while true; do
    if [ -e "${SHUTDOWN_MARKER_FILE}" ] ; then
      exit 0
    fi

    sleep 1
done

