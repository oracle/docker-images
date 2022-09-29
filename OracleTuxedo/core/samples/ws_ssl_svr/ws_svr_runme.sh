#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# 
# Shell script to build and run ws_svr.  It assume TUXDIR has been set, or that 
# Tuxedo has been installed to: ~/tuxHome/tuxedo12.1.3.0.0   If not, invoke 
# this script with a single argument indicating the location of TUXDIR.
#
# Usage: source ws_svr_runme.sh
#
mkdir -p /u01/oracle/user_projects
cd /u01/oracle/user_projects || return 1
rm -rf ws_svr
mkdir ws_svr
cd ws_svr || return 1

# Create environment setup script setenv.sh
HOSTNAME=$(uname -n)
APPDIR=$(pwd)
export HOSTNAME APPDIR
export WS_PORT=9055
export SSL_PORT=9060
#export TUX_LOADBAL_IP="138.3.79.82"
export SEC_PRINCIPAL_NAME="ISH_tuxqa"            # ssl

cat >setenv.sh << EndOfFile
source ${TUXDIR}/tux.env
export HOSTNAME=${HOSTNAME}
export APPDIR=${APPDIR}
export TUXCONFIG=${APPDIR}/tuxconfig
export TM_SECURITY_CONFIG=NONE
export TM_ALLOW_NOTLS=Y
export SSL_PORT=${SSL_PORT}                      # ssl
export ULOG_SSLINFO=yes                          # ssl
export TM_MIN_PUB_KEY_LENGTH=1024                # ssl
export SEC_PRINCIPAL_NAME=${SEC_PRINCIPAL_NAME}  # ssl
export PASSVAR=tuxsvr123                         # ssl
export IPCKEY=112233
export NLSPORT=12233
export JMXPORT=22233
export WSNADDR="//${HOSTNAME}:${WS_PORT}"
unset NATADDR_OPT
if [[ -n "${TUX_LOADBAL_IP}" ]]; then
    export NATADDR_OPT=" -H //${TUX_LOADBAL_IP}:${WS_PORT} "
fi
EndOfFile

# shellcheck disable=SC1091
source ./setenv.sh



# create ssl certificates and PKCS12 wallet
WALLET_DIR=${APPDIR}/wallet/wallet.${SEC_PRINCIPAL_NAME}
mkdir -p "${WALLET_DIR}"
mkdir -p "${APPDIR}"/CA

    cd "${APPDIR}"/CA || return 1
    mkdir certs newcerts private
    cp -p  /u01/oracle/openssl.cnf .
    touch index.txt 
    touch certindex.txt
    echo "0100" > serial

    # create CA key and certificate
    openssl req -new -x509 -extensions v3_ca -keyout private/ca_key.pem -out certs/ca_cert.pem \
                -days 3650 -config ./openssl.cnf  \
                -passout pass:'ca123'  \
                -subj "/C=US/ST=CA/L=SV/O=OraTux/OU=IT/CN=ISH_tuxsvr"

    # create tux server key and tux server certificate signing request (CSR)
    openssl req -new -nodes -out tuxsvr-req.pem -keyout private/tuxsvr_key.pem \
                -config ./openssl.cnf \
                -subj "/C=US/ST=CA/L=SV/O=OraTux/OU=IT/CN=ISH_tuxsvr"

    # sign the tux server CSR using CA cert to create the tux server certificate
    openssl ca -out certs/tuxsvr_cert.pem -config ./openssl.cnf -passin pass:ca123 \
               -batch -infiles tuxsvr-req.pem

    # create the PKCS12 wallet
    cat certs/tuxsvr_cert.pem certs/ca_cert.pem private/tuxsvr_key.pem > pre-p12.pem
    openssl pkcs12 -export -in pre-p12.pem -password pass:"${PASSVAR}"  -out "${WALLET_DIR}"/ewallet.p12
    echo "Created ewallet.p12 in ${WALLET_DIR}"

    cd "${APPDIR}" || return 1


# clean up from any previous run
tmshutdown -y &>/dev/null 
rm -Rf serverws simpserv tuxconfig ubbws ULOG.*

# Create the Tuxedo configuration file
cat >ubbws << EndOfFile
*RESOURCES
IPCKEY          $IPCKEY
DOMAINID        ws_svr
MASTER          site1
MAXACCESSERS    50
MAXSERVERS      20
MAXSERVICES     10
MODEL           SHM
LDBAL           Y
SECURITY        NONE

*MACHINES
"$HOSTNAME" LMID=site1
            APPDIR="$APPDIR"
            TUXCONFIG="$APPDIR/tuxconfig"
            TUXDIR="$TUXDIR"
            MAXWSCLIENTS=5
            SEC_PRINCIPAL_NAME="$SEC_PRINCIPAL_NAME"
            SEC_PRINCIPAL_LOCATION="$APPDIR/wallet"
            SEC_PRINCIPAL_PASSVAR="PASSVAR"

*GROUPS
APPGRP      LMID=site1  GRPNO=1  OPENINFO=NONE
WSGRP       LMID=site1  GRPNO=2  OPENINFO=NONE

*SERVERS
serverws    SRVGRP=APPGRP  SRVID=1  CLOPT="-A"
simpserv    SRVGRP=APPGRP  SRVID=3  CLOPT="-A"
WSL         SRVGRP=WSGRP  
            SRVID=10  
            CLOPT="-A -- -n ${WSNADDR} -m 2 ${NATADDR_OPT} -p 2071 -P 2075 -S ${SSL_PORT} -R 3600"
            RESTART=Y     
            MAXGEN=10 
            GRACE=3600

*SERVICES
BASICWS
TOUPPER

EndOfFile

# Get the sources if not already in this directory
if [ ! -r serverws.c ]
    then
    cp /u01/oracle/serverws.c .
fi
if [ ! -r simpserv.c ]
    then
    cp /u01/oracle/simpserv.c .
fi

# Compile the configuration file and build the client and server
# "cat /dev/null" below makes "tmloadcf" take the password from "PASSVAR"
# shellcheck disable=SC2002
cat /dev/null | tmloadcf -y ubbws
buildserver -o serverws -f serverws.c -s BASICWS
buildserver -o simpserv -f simpserv.c -s TOUPPER

# Boot up the domain
tmboot -y

cat "${APPDIR}"/ULOG*

while true
do
    ONE_HOUR=3600
    sleep ${ONE_HOUR}
done

# Shutdown the domain
#tmshutdown -y

