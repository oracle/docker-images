#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
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
  echo "NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)
DISABLE_OOB=ON
SQLNET.EXPIRE_TIME=3" > "$ORACLE_HOME"/network/admin/sqlnet.ora

  #listener.ora 
echo "DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" >> "$ORACLE_HOME"/network/admin/listener.ora

 #tnsnames.ora
 #Update PDB Alias names in tnsnames.ora till the DBCA code add entry for the same.
  echo "$ORACLE_PDB=
(DESCRIPTION =
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)" >> "$ORACLE_HOME"/network/admin/tnsnames.ora

}

function setupNetworkConfigFREE {
  # sqlnet.ora
  echo "NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)
DISABLE_OOB=ON
SQLNET.EXPIRE_TIME=3" > "$ORACLE_HOME"/network/admin/sqlnet.ora

# TNS Names.ora
   echo "FREEPDB1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = FREEPDB1)
    )
  )
" >> "$ORACLE_HOME"/network/admin/tnsnames.ora
}

function dbSetupSQL {
  # Remove second control file, fix local_listener, make PDB auto open, enable EM global port
  # Create externally mapped oracle user for health check
  sqlplus / as sysdba << EOF
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

}

function enableLoggingSQL {
  
  if [ "$ENABLE_ARCHIVELOG" = "true" ]; then
    enableArchiveLogCmd="ALTER DATABASE ARCHIVELOG;"
  fi
    
  if [ "$ENABLE_FORCE_LOGGING" = "true" ]; then
    enableForceLoggingCmd="ALTER DATABASE FORCE LOGGING;"
  fi

  sqlplus / as sysdba << EOF
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
$enableArchiveLogCmd
$enableForceLoggingCmd
ALTER DATABASE OPEN;

exit;
EOF

}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Creating Primary database/True Cache for FREE edition
if [ "${ORACLE_SID}" = "FREE" ]; then

  if [ "${TRUE_CACHE}" == "true" ]; then

    # Validation: Checking if ORACLE_PWD is provided or not
    if [[ -z "$ORACLE_PWD" ]]; then
      echo "ERROR: Please provide sys password of the primary database as ORACLE_PWD env variable. Exiting..."
      exit 1
    fi

    # Validation: Check if PRIMARY_DB_CONN_STR is provided or not
    if [[ -z "${PRIMARY_DB_CONN_STR}" ]] || [[ $PRIMARY_DB_CONN_STR != *:*/* ]]; then
      echo "ERROR: Please provide PRIMARY_DB_CONN_STR in <HOST>:<PORT>/<SERVICE_NAME> format to connect with primary database. Exiting..."
      exit 1
    fi

    # Check for password file existence before we start the dbca command for TrueCache instance creation.
    echo "Check and wait for the existence of $PRIMARY_DB_PWD_FILE..."
    while [ ! -e "$PRIMARY_DB_PWD_FILE" ]
    do  
    sleep 1
    done
    echo "$PRIMARY_DB_PWD_FILE found!"   

    dbca -silent -createTrueCacheInstance -gdbName "$ORACLE_SID" -sid "$ORACLE_SID" -sourceDBConnectionString "$PRIMARY_DB_CONN_STR" -passwordFileFromSourceDB "$PRIMARY_DB_PWD_FILE" ORACLE_HOSTNAME="$ORACLE_HOSTNAME" <<EOF
${ORACLE_PWD}
EOF
    [ $? -eq 0 ] || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log

    # Setup network related configuration
    setupNetworkConfigFREE;

    exit 0
  fi

  # Auto generate ORACLE PWD if not passed on
  export ORACLE_PWD=${ORACLE_PWD:-"$(openssl rand -hex 8)"}
  
  # Set character set
  su -c "sed -i -e \"s|^CHARSET=.*$|CHARSET=$ORACLE_CHARACTERSET|g\" /etc/sysconfig/\"$CONF_FILE\""

  # Creating database for FREE edition
  su -c '/etc/init.d/oracle-free-23ai configure << EOF
${ORACLE_PWD}
${ORACLE_PWD}
EOF
'
  # Setting up network config for FREE database
  setupNetworkConfigFREE;

  # Setting up database
  dbSetupSQL;

  if [ "$ENABLE_ARCHIVELOG" = "true" ] || [ "$ENABLE_FORCE_LOGGING" = "true" ]; then
    enableLoggingSQL;
  fi

  exit 0
fi;

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
if [[ "${CLONE_DB}" == "true" ]] || [[ "${STANDBY_DB}" == "true" ]] || [[ "${TRUE_CACHE}" == "true" ]]; then
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
      dbca -silent -createDuplicateDB -gdbName "$PRIMARY_DB_NAME" -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" ${DBCA_CRED_OPTIONS} -sid "$ORACLE_SID" -createAsStandby -datafileDestination $ORACLE_BASE/oradata -useOMF true -dbUniquename "$ORACLE_SID" ORACLE_HOSTNAME="$ORACLE_HOSTNAME" ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
  elif [ "${CLONE_DB}" = "true" ]; then 
             # Creating clone database or Duplicate database (No -createAsStandby) after duplicating a primary database; CLONE_DB is set to true here
            dbca -silent -createDuplicateDB -gdbName "$ORACLE_SID" -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" ${DBCA_CRED_OPTIONS} -sid "$ORACLE_SID" -databaseConfigType SINGLE -datafileDestination $ORACLE_BASE/oradata -useOMF true -dbUniquename "$ORACLE_SID" ORACLE_HOSTNAME="$ORACLE_HOSTNAME" ||
            cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
            cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
  elif  [ "$TRUE_CACHE" = "true" ]; then
      if [ -n "$TRUE_CACHE_BLOB" ]; then
          SOURCE_DB_BASED_ARGS="-trueCacheBlobFromSourceDB $TRUE_CACHE_BLOB";     
          # Check for BLOB file existence before we start the dbca command for TrueCache instance creation.
          echo "Check and wait for the existence of $TRUE_CACHE_BLOB..."
          while [ ! -e "$TRUE_CACHE_BLOB" ]
          do  
          sleep 1
          done
          echo "$TRUE_CACHE_BLOB found!"
      else
          SOURCE_DB_BASED_ARGS="-passwordFileFromSourceDB $PRIMARY_DB_PWD_FILE";
          # Check for password file existence before we start the dbca command for TrueCache instance creation.
          echo "Check and wait for the existence of $PRIMARY_DB_PWD_FILE..."
          while [ ! -e "$PRIMARY_DB_PWD_FILE" ]
          do  
          sleep 1
          done
          echo "$PRIMARY_DB_PWD_FILE found!"

          if [ -n "$PRIMARY_DB_TDE_WALLET" ]; then
              SOURCE_DB_BASED_ARGS="$SOURCE_DB_BASED_ARGS -tdeWalletFromSourceDB $PRIMARY_DB_TDE_WALLET"
              # Check for TDE wallet existence before we start the dbca command for TrueCache instance creation.
              echo "Check and wait for the existence of $PRIMARY_DB_TDE_WALLET..."
              while [ ! -e "$PRIMARY_DB_TDE_WALLET" ]
              do  
              sleep 1
              done
              echo "$PRIMARY_DB_TDE_WALLET found!"
          fi;   
      fi;
	    
	    # Creating TRUE CACHE database instance; TRUE_CACHE is set to true here
	    # Checking if INIT_SGA_SIZE & INIT_PGA_SIZE is provided by the user
	    SGA_TARGET_IN_MB="";
	    PGA_AGGREGATE_TARGET_IN_MB="";
	    if [[ "${INIT_SGA_SIZE}" != "" && "${INIT_PGA_SIZE}" != "" ]]; then
            	SGA_TARGET_IN_MB="-sgaTargetInMB $INIT_SGA_SIZE";
	        PGA_AGGREGATE_TARGET_IN_MB="-pgaAggregateTargetInMB $INIT_PGA_SIZE";
	    fi;
	    dbca -silent -createTrueCacheInstance -gdbName "$ORACLE_SID" -sid "$ORACLE_SID" -sourceDBConnectionString "$PRIMARY_DB_CONN_STR" ${DBCA_CRED_OPTIONS} $SOURCE_DB_BASED_ARGS $SGA_TARGET_IN_MB $PGA_AGGREGATE_TARGET_IN_MB ORACLE_HOSTNAME="$ORACLE_HOSTNAME" <<EOF
${ORACLE_PWD}
${TDE_WALLET_PWD}
EOF
	[ $? -eq 0 ] || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log

  fi

  # Setup network related configuration
  setupNetworkConfig; 

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
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" "$ORACLE_BASE"/dbca.rsp
if [[ -n "${WALLET_DIR}" ]] && [[ -f $WALLET_DIR/ewallet.p12 ]] || [[ -z "$ORACLE_PWD" ]]; then
   # Deleting password options from dbca response file as wallet will be used for credentials or ORACLE_PWD is not provided (i.e. password auto-generation intended)
   sed -i -e "/###ORACLE_PWD###/d" "$ORACLE_BASE"/dbca.rsp
else
   sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" "$ORACLE_BASE"/dbca.rsp
fi

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
fi;

# Directory for storing archive logs
export ARCHIVELOG_DIR=$ORACLE_BASE/oradata/$ORACLE_SID/$ARCHIVELOG_DIR_NAME

# If TDE wallet password is present and EE edition, then prepare dbca options for TDE
if [[ "${TDE_WALLET_PWD}" != "" ]]; then
  if [ -n "${ORACLE_EDITION}" ] && [ "${ORACLE_EDITION^^}" != "ENTERPRISE" ]; then
    echo "Transparent Data Encryption (TDE) is supported only for Enterprise Edition of database. Exiting...";
    exit 1;
  fi;
  DBCA_TDE_CONFIG_OPTIONS="-configureTDE true -tdeWalletRoot ${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID} -tdeWalletLoginType AUTO_LOGIN -encryptTablespaces all"
fi

# Run DBCA
dbca -silent -createDatabase -createListener LISTENER:1521 -enableArchive "$ENABLE_ARCHIVELOG" -archiveLogDest "$ARCHIVELOG_DIR" -enableForceLogging "$ENABLE_FORCE_LOGGING" ${DBCA_CRED_OPTIONS} -datafileDestination $ORACLE_BASE/oradata -useOMF true -responseFile "$ORACLE_BASE"/dbca.rsp ${DBCA_TDE_CONFIG_OPTIONS} <<< "${TDE_WALLET_PWD}" || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log

# Create/update network related config files (sqlnet.ora, listener.ora)
setupNetworkConfig;

# Setting up database
dbSetupSQL;

# Remove temporary response file
rm "$ORACLE_BASE"/dbca.rsp

