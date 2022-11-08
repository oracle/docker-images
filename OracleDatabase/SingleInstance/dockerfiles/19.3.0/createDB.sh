#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Creates an Oracle Database based on following parameters:
#              $ORACLE_SID: The Oracle SID and CDB name
#              $ORACLE_PDB: The PDB name
#              $ORACLE_PWD: The Oracle password
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -e

############## Setting up network related config files (sqlnet.ora, listener.ora) ##############
function setupNetworkConfig {
  mkdir -p "$ORACLE_HOME"/network/admin

  # sqlnet.ora
  echo "NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > "$ORACLE_HOME"/network/admin/sqlnet.ora

  # listener.ora
  echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" > "$ORACLE_HOME"/network/admin/listener.ora

}

####################### Setting up tnsnames.ora ##############################
function setupTnsnames {
  mkdir -p "$ORACLE_HOME"/network/admin

  # tnsnames.ora
  echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > "$ORACLE_HOME"/network/admin/tnsnames.ora
  echo "$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)" >> "$ORACLE_HOME"/network/admin/tnsnames.ora

}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCLCDB}

# Check whether ORACLE_PDB is passed on
export ORACLE_PDB=${2:-ORCLPDB1}

# Setting up file creation mask for newly created files (dbca response templates)
umask 177

# Checking if only one of INIT_SGA_SIZE & INIT_PGA_SIZE is provided by the user
if [[ "${INIT_SGA_SIZE}" != "" && "${INIT_PGA_SIZE}" == "" ]] || [[ "${INIT_SGA_SIZE}" == "" && "${INIT_PGA_SIZE}" != "" ]]; then
   echo "ERROR: Provide both the values, INIT_SGA_SIZE and INIT_PGA_SIZE or neither of them. Exiting.";
   exit 1;
fi;

# If wallet is present for database credentials then prepare dbca options to use
if [[ -n "${WALLET_DIR}" ]] && [[ -f $WALLET_DIR/ewallet.p12 ]]; then
  # Oracle Wallet is present
  export DBCA_CRED_OPTIONS="-useWalletForDBCredentials true  -dbCredentialsWalletLocation ${WALLET_DIR}"
else
  if [[ "${CLONE_DB}" == "true" ]] || [[ "${STANDBY_DB}" == "true" ]]; then
    # Validation: Checking if ORACLE_PWD is provided or not
    if [[ -z "$ORACLE_PWD" ]]; then
      echo "ERROR: Please provide sys password of the primary database as ORACLE_PWD env variable. Exiting..."
      exit 1
    fi

    # Creating temporary response file containing sysPassword for clone/standby cases
    cat > "$ORACLE_BASE"/dbca.rsp <<EOF
sysPassword=${ORACLE_PWD}
EOF

    export DBCA_CRED_OPTIONS=" -responseFile $ORACLE_BASE/dbca.rsp"
  else
    # If ORACLE_PWD is not provided, use DBCA auto password generation for generating a random, strong password
    if [[ -z "${ORACLE_PWD}" ]]; then
      export DBCA_CRED_OPTIONS="-autoGeneratePasswords"
    fi
  fi

fi

# Clone DB/ Standby DB creation path
if [[ "${CLONE_DB}" == "true" ]] || [[ "${STANDBY_DB}" == "true" ]]; then
  # Reverting umask to original value for clone/standby DB cases
  umask 022
  
  # Validation: Check if PRIMARY_DB_CONN_STR is provided or not
  if [[ -z "${PRIMARY_DB_CONN_STR}" ]] || [[ $PRIMARY_DB_CONN_STR != *:*/* ]]; then
    echo "ERROR: Please provide PRIMARY_DB_CONN_STR in <HOST>:<PORT>/<SERVICE_NAME> format to connect with primary database. Exiting..."
    exit 1
  fi

  # Primary database parameters extration
  PRIMARY_DB_NAME=$(echo "${PRIMARY_DB_CONN_STR}" | cut -d '/' -f 2)

  # Creating the database using the dbca command
  if [ "${STANDBY_DB}" = "true" ]; then
    # Creating standby database
    dbca -silent -createDuplicateDB -gdbName "$PRIMARY_DB_NAME" -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" ${DBCA_CRED_OPTIONS} -sid "$ORACLE_SID" -createAsStandby -dbUniquename "$ORACLE_SID" ORACLE_HOSTNAME="$ORACLE_HOSTNAME" ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
  else
    # Creating clone database using DBCA after duplicating a primary database; CLONE_DB is set to true here
    dbca -silent -createDuplicateDB -gdbName "${ORACLE_SID}" -primaryDBConnectionString "${PRIMARY_DB_CONN_STR}" ${DBCA_CRED_OPTIONS} -sid "${ORACLE_SID}" -databaseConfigType SINGLE -useOMF true -dbUniquename "${ORACLE_SID}" ORACLE_HOSTNAME="${ORACLE_HOSTNAME}" ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
  fi

  # Setup tnsnames.ora after DBCA command execution, otherwise tnsnames gets overwritten by DBCA
  setupTnsnames;

  # Stopping the Listener
  lsnrctl stop;

  # Setup other network related configuration (sqlnet.ora, listener.ora)
  setupNetworkConfig;

  # Starting the Listener
  lsnrctl start;

  # Remove temporary response file
  if [ -f "$ORACLE_BASE"/dbca.rsp ]; then
    rm "$ORACLE_BASE"/dbca.rsp
  fi

  exit 0
fi

# Replace place holders in response file
cp "$ORACLE_BASE"/"$CONFIG_RSP" "$ORACLE_BASE"/dbca.rsp
# Reverting umask to original value
umask 022
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" "$ORACLE_BASE"/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" "$ORACLE_BASE"/dbca.rsp
if [[ -n "${WALLET_DIR}" ]] && [[ -f $WALLET_DIR/ewallet.p12 ]] || [[ -z "$ORACLE_PWD" ]]; then
  # Deleting password options from dbca response file as wallet will be used for credentials or ORACLE_PWD is not provided (i.e. password auto-generation intended)
  sed -i -e "/###ORACLE_PWD###/d" "$ORACLE_BASE"/dbca.rsp
else
  sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" "$ORACLE_BASE"/dbca.rsp
fi
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" "$ORACLE_BASE"/dbca.rsp

# If both INIT_SGA_SIZE & INIT_PGA_SIZE aren't provided by user
if [[ "${INIT_SGA_SIZE}" == "" && "${INIT_PGA_SIZE}" == "" ]]; then
    # If AUTO_MEM_CALCULATION isn't set to false and a given amount of memory is allocated,
    # we set the total memory with the amount of memory allocated for the container.
    # Otherwise, we keep the default of 2GB.
    if [[ "${AUTO_MEM_CALCULATION}" != "false" && "${ALLOCATED_MEMORY}" -le 655360 ]]; then
      sed -i -e "s|totalMemory=.*|totalMemory=${ALLOCATED_MEMORY?}|g" "$ORACLE_BASE"/dbca.rsp
    fi
else
    sed -i -e "s|totalMemory=.*||g" "$ORACLE_BASE"/dbca.rsp
    sed -i -e "s|initParams=.*|&,sga_target=${INIT_SGA_SIZE}M,pga_aggregate_target=${INIT_PGA_SIZE}M|g" "$ORACLE_BASE"/dbca.rsp
fi

# Adding INIT_CPU_COUNT initParam if provided
if [ -n "${INIT_CPU_COUNT}" ]; then
  sed -i -e "s|initParams=.*|&,cpu_count=${INIT_CPU_COUNT}|g" "$ORACLE_BASE"/dbca.rsp
fi

# Adding INIT_PROCESSES initParam if provided
if [ -n "${INIT_PROCESSES}" ]; then
  sed -i -e "s|initParams=.*|&,processes=${INIT_PROCESSES}|g" "$ORACLE_BASE"/dbca.rsp
fi

# Create network related config files (sqlnet.ora, listener.ora)
setupNetworkConfig;

# Directory for storing archive logs
export ARCHIVELOG_DIR=$ORACLE_BASE/oradata/$ORACLE_SID/$ARCHIVELOG_DIR_NAME

# Start LISTENER and run DBCA
lsnrctl start &&
dbca -silent -createDatabase -enableArchive "$ENABLE_ARCHIVELOG" -archiveLogDest "$ARCHIVELOG_DIR" ${DBCA_CRED_OPTIONS} -responseFile "$ORACLE_BASE"/dbca.rsp ||
 cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
 cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log

# Setup tnsnames.ora after DBCA command execution, otherwise tnsnames gets overwritten by DBCA
setupTnsnames;

# Remove second control file, fix local_listener, make PDB auto open, enable EM global port
# Create externally mapped oracle user for health check
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   ALTER SYSTEM SET local_listener='';
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);

   ALTER SESSION SET "_oracle_script" = true;
   CREATE USER OPS\$oracle IDENTIFIED EXTERNALLY;
   GRANT CREATE SESSION TO OPS\$oracle;
   GRANT SELECT ON sys.v_\$pdbs TO OPS\$oracle;
   GRANT SELECT ON sys.v_\$database TO OPS\$oracle;
   ALTER USER OPS\$oracle SET container_data=all for sys.v_\$pdbs container = current;

   exit;
EOF

# Remove temporary response file
rm "$ORACLE_BASE"/dbca.rsp
