#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
# 
# Since: June, 2022
# Author: abhishek.by.kumar@oracle.com
# Description: Configure TCPS for the database
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Exit immediately if a command exits with non-zero exit code
set -e

############# Function for setting up the client wallet ######################################
function setupClientWallet() {
    # Client wallet location
    CLIENT_WALLET_LOC="${ORACLE_BASE}/oradata/clientWallet"
    echo -e "\n\nSetting up Client Wallet in location ${CLIENT_WALLET_LOC}...\n"

    if [ ! -d  "${CLIENT_WALLET_LOC}" ]; then
        mkdir -p "${CLIENT_WALLET_LOC}"
    else
        # Clean-up the client wallet directory
        rm -f "${CLIENT_WALLET_LOC}"/*
    fi

    # Create the client wallet
    orapki wallet create -wallet "${CLIENT_WALLET_LOC}" -pwd "$1" -auto_login
    # Add the certificate
    orapki wallet add -wallet "${CLIENT_WALLET_LOC}" -pwd "$1" -trusted_cert -cert /tmp/"$(hostname)"-certificate.crt
    # Removing cert from /tmp location
    rm /tmp/"$(hostname)"-certificate.crt

    # Generate tnsnames.ora and sqlnet.ora for the consumption by the client
    echo "${ORACLE_SID}=
(DESCRIPTION=
  (ADDRESS=
    (PROTOCOL=TCPS)
    (HOST=localhost)
    (PORT=1522)
  )
  (CONNECT_DATA=
    (SERVER=dedicated)
    (SERVICE_NAME=${ORACLE_SID})
  )
)

${ORACLE_PDB}=
(DESCRIPTION=
  (ADDRESS=
    (PROTOCOL=TCPS)
    (HOST=localhost)
    (PORT=1522)
  )
  (CONNECT_DATA=
    (SERVER=dedicated)
    (SERVICE_NAME=${ORACLE_PDB})
  )
)" > "${CLIENT_WALLET_LOC}"/tnsnames.ora

    echo "WALLET_LOCATION =
(SOURCE =
  (METHOD = FILE)
  (METHOD_DATA =
    (DIRECTORY = ./)
  )
)

SQLNET.AUTHENTICATION_SERVICES = (TCPS)
SSL_CLIENT_AUTHENTICATION = FALSE" > "${CLIENT_WALLET_LOC}"/sqlnet.ora
}

########### Configure Oracle Net Service for TCPS (sqlnet.ora and listener.ora) ##############
function configure_netservices() {
   # Add wallet location and SSL_CLIENT_AUTHENTICATION to sqlnet.ora and listener.ora
   echo -e "\n\nConfiguring Oracle Net service for TCPS...\n"
   echo "WALLET_LOCATION =
(SOURCE =
   (METHOD = FILE)
   (METHOD_DATA =
     (DIRECTORY = $WALLET_LOC)
   )
)

SSL_CLIENT_AUTHENTICATION = FALSE" | tee -a "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/{sqlnet.ora,listener.ora} > /dev/null

   # Add listener for TCPS
   sed -i "/TCP/a\
\ \ \ \ (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = ${TCPS_PORT}))
" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora

}


###########################################
################## MAIN ###################
###########################################

# External certificate location
CERT_LOC="${ORACLE_BASE}/cert"
# Oracle wallet location which stores the certificate
WALLET_LOC="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/.tls-wallet"
# Random wallet Password
WALLET_PWD=$(openssl rand -hex 4)
# Export ORACLE_PDB value
export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}
ORACLE_PDB=${ORACLE_PDB^^}

# Creating the wallet
echo -e "\n\nCreating Oracle Wallet for the database server side certificate...\n"
if [ ! -d "${WALLET_LOC}" ]; then
    mkdir -p "${WALLET_LOC}"
    # Configure sqlnet.ora and listener.ora for TCPS
    configure_netservices
else 
    echo -e "\nCleaning up existing wallet..."
    rm -f "${WALLET_LOC}"/*
fi
orapki wallet create -wallet "${WALLET_LOC}" -pwd "${WALLET_PWD}" -auto_login
echo -e "\nOracle Wallet location: ${WALLET_LOC}\n"

if [ -e "${CERT_LOC}/tls.crt" ]; then
    # Add this certificate to the wallet
    orapki wallet add -wallet "${WALLET_LOC}" -pwd "${WALLET_PWD}" -trusted_cert -cert "${CERT_LOC}/tls.crt"
else
    # Create a self-signed certificate using orapki utility; VALIDITY: 1095 days
    orapki wallet add -wallet "${WALLET_LOC}" -pwd "${WALLET_PWD}" -dn "CN=localhost" -keysize 1024 -self_signed -validity 1095
fi

# Restart listener to enable TCPS (Reload wouldn't work here)
lsnrctl stop
lsnrctl start

# Export the cert to be updated in the client wallet
orapki wallet export -wallet "${WALLET_LOC}" -pwd "${WALLET_PWD}" -dn "CN=localhost" -cert /tmp/"$(hostname)"-certificate.crt

# Update the client wallet
setupClientWallet "${WALLET_PWD}"
