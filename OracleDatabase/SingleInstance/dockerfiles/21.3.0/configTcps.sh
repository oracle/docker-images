#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
# 
# Since: August, 2022
# Author: abhishek.by.kumar@oracle.com
# Description: Configure TCPS for the database
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Exit immediately if a command exits with non-zero exit code
set -e

############# Function for setting up the client wallet ######################################
function setupClientWallet() {
    echo -e "\n\nSetting up Client Wallet in location ${CLIENT_WALLET_LOC}...\n"

    if [ ! -d  "${CLIENT_WALLET_LOC}" ]; then
        mkdir -p "${CLIENT_WALLET_LOC}"
    else
        # Clean-up the client wallet directory
        rm -f "${CLIENT_WALLET_LOC}"/*
    fi

    # Create the client wallet
    orapki wallet create -wallet "${CLIENT_WALLET_LOC}" -pwd "$WALLET_PWD" -auto_login
    # Add the certificate
    orapki wallet add -wallet "${CLIENT_WALLET_LOC}" -pwd "$WALLET_PWD" -trusted_cert -cert /tmp/"$(hostname)"-certificate.crt
    # Removing cert from /tmp location
    rm /tmp/"$(hostname)"-certificate.crt

    # Generate tnsnames.ora and sqlnet.ora for the consumption by the client
    echo "${ORACLE_SID}=
(DESCRIPTION=
  (ADDRESS=
    (PROTOCOL=TCPS)
    (HOST=${HOSTNAME:-localhost})
    (PORT=${TCPS_PORT})
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
    (HOST=${HOSTNAME:-localhost})
    (PORT=${TCPS_PORT})
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
   echo "WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))
SSL_CLIENT_AUTHENTICATION = FALSE" | tee -a "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/{sqlnet.ora,listener.ora} > /dev/null

   # Add listener for TCPS
   sed -i "/TCP/a\
\ \ \ \ (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = ${TCPS_PORT}))
" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora

}

# Function for reconfiguring the Listener; 'lsnrctl reload' does't work for reconfiguration
function reconfigure_listener() {
  lsnrctl stop
  lsnrctl start
}

# Function for disabling the tcps and restore the previous Oracle Net configuration
function disable_tcps() {
  # Deleting WALLET_LOCATION and SSL_CLIENT_AUTHENTICATION params from listener.ora and sqlnet.ora and listener.ora
  sed -i -e '/WALLET_LOCATION/d' -e '/SSL_CLIENT_AUTHENTICATION/d' "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/{sqlnet,listener}.ora
  # Deleting Listener Endpoint for TCPS
  sed -i "/TCPS/d" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora
  # Reconfigure the Listener
  echo -e "\nReconfiguring the Listener...\n"
  reconfigure_listener
  # Deleting the wallet Directories
  rm -rf "$WALLET_LOC" "$CLIENT_WALLET_LOC"
}


###########################################
################## MAIN ###################
###########################################

ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"
# Export ORACLE_PDB value
if [ "$ORACLE_SID" == "XE" ]; then
  export ORACLE_PDB="XEPDB1"
else
  export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}
fi
ORACLE_PDB=${ORACLE_PDB^^}

# Oracle wallet location which stores the certificate
WALLET_LOC="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/.tls-wallet"

# Random wallet Password
WALLET_PWD=$(openssl rand -hex 4)

# Client wallet location
CLIENT_WALLET_LOC="${ORACLE_BASE}/oradata/clientWallet/${ORACLE_SID}"

# Disable TCPS control flow
if [ "${1^^}" == "DISABLE" ]; then
  disable_tcps
  exit 0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  # If TCPS_PORT is not set in the environment, honor the TCPS_PORT passed as the positional argument
  TCPS_PORT=${TCPS_PORT:-"$1"}
  HOSTNAME="$2"
else
  HOSTNAME="$1"
fi

# Default TCPS_PORT value
TCPS_PORT=${TCPS_PORT:-2484}

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

# Create a self-signed certificate using orapki utility; VALIDITY: 1095 days
orapki wallet add -wallet "${WALLET_LOC}" -pwd "${WALLET_PWD}" -dn "CN=localhost" -keysize 2048 -self_signed -validity 1095


# Reconfigure listener to enable TCPS (Reload wouldn't work here)
reconfigure_listener

# Export the cert to be updated in the client wallet
orapki wallet export -wallet "${WALLET_LOC}" -pwd "${WALLET_PWD}" -dn "CN=localhost" -cert /tmp/"$(hostname)"-certificate.crt

# Update the client wallet
setupClientWallet
