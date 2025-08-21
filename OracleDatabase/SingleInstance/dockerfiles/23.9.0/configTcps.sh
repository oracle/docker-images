#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
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
    orapki wallet create -wallet "${CLIENT_WALLET_LOC}" -auto_login <<EOF
${WALLET_PWD}
${WALLET_PWD}
EOF

if [ "${CUSTOM_CERTS}" == false ]; then
    # Add the certificate
    orapki wallet add -wallet "${CLIENT_WALLET_LOC}" -trusted_cert -cert "/tmp/$(hostname)-certificate.crt" <<EOF
${WALLET_PWD}
EOF

    # Removing cert from /tmp location
    rm /tmp/"$(hostname)"-certificate.crt
else
    orapki wallet add -wallet "${CLIENT_WALLET_LOC}" -trusted_cert -cert "${INTERMEDIATE_CERT_LOCATION}" <<EOF
${WALLET_PWD}
EOF

    # removing temp cert file
    rm "${INTERMEDIATE_CERT_LOCATION}"
fi

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

   # Disable OOB in sqlnet.ora of DB wallet
   echo "DISABLE_OOB=ON" >> "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/sqlnet.ora

   # To prevent Oracle from running out of processes because of abnormal client terminations
   echo "SQLNET.EXPIRE_TIME=3" >> "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/sqlnet.ora

   # Add listener for TCPS
   sed -i "/TCP/a\
\ \ \ \ (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = ${TCPS_PORT}))
" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora

}

# Function for reconfiguring the Listener; 'lsnrctl reload' does't work for reconfiguration
function reconfigure_listener() {
  lsnrctl stop
  lsnrctl start

  # To quickly register a service
  echo 'alter system register;' | sqlplus -s / as sysdba
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

export ORACLE_SID
ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"

# Export ORACLE_PDB value
if [ "$ORACLE_SID" == "FREE" ]; then
  export ORACLE_PDB="FREEPDB1"
else
  export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}
fi
ORACLE_PDB=${ORACLE_PDB^^}


# Oracle wallet location which stores the certificate
WALLET_LOC="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/.tls-wallet"

# Random wallet Password
WALLET_PWD=$(openssl rand -hex 8)
# Random pkcs12 file Password
PKCS12_PWD=$(openssl rand -hex 8)

# Client wallet location
CLIENT_WALLET_LOC="${ORACLE_BASE}/oradata/clientWallet/${ORACLE_SID}"

if [[ -z "${TCPS_CERTS_LOCATION}" ]]; then
  CUSTOM_CERTS=false
else
  CUSTOM_CERTS=true

  # Client Cert location (from user)
  CLIENT_CERT_LOCATION="${TCPS_CERTS_LOCATION}"/cert.crt # certificate file

  # Intermediate Cert location (Extracted from user provided chained certificate)
  INTERMEDIATE_CERT_LOCATION="/tmp/cert_temp.crt" # certificate file

  # Client key location
  CLIENT_KEY_LOCATION="${TCPS_CERTS_LOCATION}"/client.key # client key

  # Extracting intermediate certificate from user given chain certificate file
  # Removing the first occurence of following  pattern
  sed '{0,/-END CERTIFICATE-/d}' "$CLIENT_CERT_LOCATION" > "$INTERMEDIATE_CERT_LOCATION"
fi

# Disable TCPS control flow
if [ "${1^^}" == "DISABLE" ]; then
  disable_tcps
  exit 0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  # If TCPS_PORT is not set in the environment, honor the TCPS_PORT passed as the positional argument
  TCPS_PORT=${TCPS_PORT:-"$1"}
  HOSTNAME="$2"
   # Optional wallet password
  if [[ -n "$3" ]]; then
      WALLET_PWD="$3"
  fi
   
else
  HOSTNAME="$1"
   # Optional wallet password
  if [[ -n "$2" ]]; then
      WALLET_PWD="$2"
  fi
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
orapki wallet create -wallet "${WALLET_LOC}" -auto_login <<EOF
${WALLET_PWD}
${WALLET_PWD}
EOF

echo -e "\nOracle Wallet location: ${WALLET_LOC}\n"

if [ "${CUSTOM_CERTS}" == false ]; then
    # Create a self-signed certificate using orapki utility; VALIDITY: 365 days
    echo "Creating self-signed certs"
    orapki wallet add -wallet "${WALLET_LOC}" -dn "CN=${HOSTNAME:-localhost}" -keysize 2048 -self_signed -validity 365 <<EOF
${WALLET_PWD}
EOF
else
    # creating pkcs12 file in case of custom certs
    echo "Creating pkcs12 file"
    openssl pkcs12 -export -in "${CLIENT_CERT_LOCATION}"  -inkey "${CLIENT_KEY_LOCATION}"  -out /tmp/"$(hostname)"-open.p12 -password pass:"${PKCS12_PWD}"
  
    # Adding custom pkcs12 file in database server wallet
    echo "Importing pkcs12 file in server wallet"
    orapki wallet import_pkcs12 -wallet "${WALLET_LOC}"  -pkcs12file /tmp/"$(hostname)"-open.p12 <<EOF
${WALLET_PWD}
${PKCS12_PWD}
EOF

    # Removing pkcs12 file from /tmp location
    rm /tmp/"$(hostname)"-open.p12
fi
# Reconfigure listener to enable TCPS (Reload wouldn't work here)
reconfigure_listener

if [ "${CUSTOM_CERTS}" == false ]; then
    # Export the cert to be updated in the client wallet
    orapki wallet export -wallet "${WALLET_LOC}" -dn "CN=${HOSTNAME:-localhost}" -cert /tmp/"$(hostname)"-certificate.crt <<EOF
${WALLET_PWD}
EOF
fi

# Update the client wallet
setupClientWallet
