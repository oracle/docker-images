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

SCRIPT_BASE_DIR="${SCRIPT_BASE_DIR:-/opt/oracle/scripts/base}"
TDE_SECRET_UTILS_FILE="${TDE_SECRET_UTILS_FILE:-tdeSecretUtils.sh}"
if [ -f "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE" ]; then
  # shellcheck source=/dev/null
  . "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE"
else
  echo "ERROR: Missing required TDE helper: ${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE. Exiting..."
  exit 1
fi

############## Setting up network related config files (sqlnet.ora, listener.ora) ##############
function setupNetworkConfig {
  mkdir -p "$ORACLE_HOME"/network/admin

  # sqlnet.ora
  echo "NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)
DISABLE_OOB=ON
SQLNET.EXPIRE_TIME=3" > "$ORACLE_HOME"/network/admin/sqlnet.ora

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

############## Prepare standby TDE wallet from zip artifact ##############
function prepareStandbyTDEWalletFromZip {
  TDE_WALLET_ROOT="${TDE_WALLET_ROOT:-/opt/oracle/oradata/${ORACLE_SID}/tdewallet}"
  if ! tde_require_standby_wallet_zip "${STANDBY_TDE_WALLET_ZIP_PATH:-}"; then
    exit 1
  fi

  mkdir -p "${TDE_WALLET_ROOT}"
  unzip -oq "${ORACLE_TDE_SECRET_FILE}" -d "${TDE_WALLET_ROOT}"

  if ! find "${TDE_WALLET_ROOT}" -maxdepth 3 -type f \( -name "cwallet.sso" -o -name "ewallet.p12" \) | grep -q .; then
    echo "ERROR: No wallet files (cwallet.sso/ewallet.p12) found after extracting standby wallet artifact. Exiting..."
    exit 1
  fi

  chmod 700 "${TDE_WALLET_ROOT}" || true
}

############## Configure standby DB TDE parameters deterministically ##############
function configureStandbyTDEParameters {
  sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SYSTEM SET wallet_root='${TDE_WALLET_ROOT}' SCOPE=SPFILE SID='*';
ALTER SYSTEM SET tde_configuration='KEYSTORE_CONFIGURATION=FILE' SCOPE=BOTH SID='*';
EXIT;
EOF
}

############## Configure primary DB TDE after 19c DBCA creation ##############
function configurePrimaryTDE {
  if [[ "${TDE_ENABLED}" != "true" ]]; then
    return 0
  fi

  if [ -n "${ORACLE_EDITION}" ] && [ "${ORACLE_EDITION^^}" != "ENTERPRISE" ]; then
    echo "Transparent Data Encryption (TDE) is supported only for Enterprise Edition of database. Exiting..."
    exit 1
  fi

  if ! tde_require_primary_password; then
    exit 1
  fi

  TDE_WALLET_ROOT="${TDE_WALLET_ROOT:-/opt/oracle/oradata/${ORACLE_SID}/tdewallet}"
  mkdir -p "${TDE_WALLET_ROOT}"
  chmod 700 "${TDE_WALLET_ROOT}" || true

  echo "Configuring TDE wallet root for 19c database."
  sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SYSTEM SET wallet_root='${TDE_WALLET_ROOT}' SCOPE=SPFILE SID='*';
SHUTDOWN IMMEDIATE;
STARTUP;
ALTER SYSTEM SET tde_configuration='KEYSTORE_CONFIGURATION=FILE' SCOPE=BOTH SID='*';
ALTER SYSTEM SET ENCRYPT_NEW_TABLESPACES=ALWAYS SCOPE=BOTH;
EXIT;
EOF

  local cdb_mode
  cdb_mode="$(sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF ECHO OFF
SELECT cdb FROM v\$database;
EXIT;
EOF
)"
  cdb_mode="$(echo "${cdb_mode}" | tr -d '[:space:]')"

  if [[ "${cdb_mode}" == "YES" ]]; then
    echo "Creating TDE keystore and master key for CDB/PDB containers."
    sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER PLUGGABLE DATABASE ALL OPEN;
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "${TDE_WALLET_PWD}";
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "${TDE_WALLET_PWD}" CONTAINER=ALL;
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "${TDE_WALLET_PWD}" WITH BACKUP CONTAINER=ALL;
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "${TDE_WALLET_PWD}";
EXIT;
EOF
  else
    echo "Creating TDE keystore and master key."
    sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "${TDE_WALLET_PWD}";
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "${TDE_WALLET_PWD}";
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "${TDE_WALLET_PWD}" WITH BACKUP;
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "${TDE_WALLET_PWD}";
EXIT;
EOF
  fi
}

function normalizeStandbyOpenMode {
  STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE:-READ_ONLY}"
  STANDBY_OPEN_MODE="${STANDBY_OPEN_MODE^^}"
  if [[ "${STANDBY_OPEN_MODE}" != "READ_ONLY" && "${STANDBY_OPEN_MODE}" != "MOUNTED" ]]; then
    echo "ERROR: STANDBY_OPEN_MODE must be READ_ONLY or MOUNTED. Exiting..."
    exit 1
  fi
}

function applyStandbyOpenMode {
  normalizeStandbyOpenMode

  if [[ "${STANDBY_OPEN_MODE}" == "MOUNTED" ]]; then
    return 0
  fi

  sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_open_mode VARCHAR2(20);
  l_cdb       VARCHAR2(3);
BEGIN
  SELECT open_mode, cdb INTO l_open_mode, l_cdb FROM v\$database;
  IF l_open_mode = 'MOUNTED' THEN
    EXECUTE IMMEDIATE 'ALTER DATABASE OPEN READ ONLY';
  END IF;
  IF l_cdb = 'YES' THEN
    EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ALL OPEN READ ONLY';
  END IF;
END;
/
EXIT;
EOF
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

# Conditionally enable DBCA recovery-area options.
# Supported envs (in precedence order):
#   DB_RECOVERY_FILE_DEST / DB_RECOVERY_FILE_DEST_SIZE
#   RECOVERY_AREA_LOCATION / RECOVERY_AREA_SIZE
#   RECOVERY_AREA_DESTINATION / RECOVERY_AREA_SIZE
DBCA_RECOVERY_CONFIG_OPTIONS=""
DBCA_RECOVERY_DEST="${DB_RECOVERY_FILE_DEST:-${RECOVERY_AREA_LOCATION:-${RECOVERY_AREA_DESTINATION:-}}}"
DBCA_RECOVERY_SIZE="${DB_RECOVERY_FILE_DEST_SIZE:-${RECOVERY_AREA_SIZE:-}}"
if [[ -n "${DBCA_RECOVERY_DEST}" || -n "${DBCA_RECOVERY_SIZE}" ]]; then
  if [[ -z "${DBCA_RECOVERY_DEST}" || -z "${DBCA_RECOVERY_SIZE}" ]]; then
    echo "ERROR: Recovery area configuration requires both destination and size. Set DB_RECOVERY_FILE_DEST and DB_RECOVERY_FILE_DEST_SIZE (or RECOVERY_AREA_LOCATION/RECOVERY_AREA_SIZE). Exiting..."
    exit 1
  fi
  if [[ ! -d "${DBCA_RECOVERY_DEST}" ]]; then
    echo "ERROR: Recovery area destination does not exist: ${DBCA_RECOVERY_DEST}. Exiting..."
    exit 1
  fi
  DBCA_RECOVERY_CONFIG_OPTIONS="-recoveryAreaDestination ${DBCA_RECOVERY_DEST} -recoveryAreaSize ${DBCA_RECOVERY_SIZE}"
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
  PRIMARY_DB_NAME=${PRIMARY_DB_NAME:-$(echo "${PRIMARY_DB_CONN_STR}" | cut -d '/' -f 2)}

  # Creating the database using the dbca command
  if [ "${STANDBY_DB}" = "true" ]; then
    if [[ "${TDE_ENABLED}" == "true" ]]; then
      prepareStandbyTDEWalletFromZip
    fi

    # Creating standby database
    # Ignoring shell check so as to treat DBCA_CRED_OPTIONS as separate args to dbca
    # shellcheck disable=SC2086
    dbca -silent -createDuplicateDB -gdbName "$PRIMARY_DB_NAME" -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" ${DBCA_CRED_OPTIONS} ${DBCA_RECOVERY_CONFIG_OPTIONS} -sid "$ORACLE_SID" -createAsStandby -dbUniquename "$ORACLE_SID" ORACLE_HOSTNAME="$ORACLE_HOSTNAME" ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log

    if [[ "${TDE_ENABLED}" == "true" ]]; then
      configureStandbyTDEParameters
    fi

    applyStandbyOpenMode
  else
    # Creating clone database using DBCA after duplicating a primary database; CLONE_DB is set to true here
    # Ignoring shell check so as to treat DBCA_CRED_OPTIONS as separate args to dbca
    # shellcheck disable=SC2086
    dbca -silent -createDuplicateDB -gdbName "${ORACLE_SID}" -primaryDBConnectionString "${PRIMARY_DB_CONN_STR}" ${DBCA_CRED_OPTIONS} ${DBCA_RECOVERY_CONFIG_OPTIONS} -sid "${ORACLE_SID}" -databaseConfigType SINGLE -useOMF true -dbUniquename "${ORACLE_SID}" ORACLE_HOSTNAME="${ORACLE_HOSTNAME}" ||
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
DBCA_TEMPLATE_PATH="${SCRIPT_BASE_DIR}/${CONFIG_RSP}"
if [ ! -f "${DBCA_TEMPLATE_PATH}" ]; then
  DBCA_TEMPLATE_PATH="${ORACLE_BASE}/${CONFIG_RSP}"
fi
cp "${DBCA_TEMPLATE_PATH}" "${ORACLE_BASE}/dbca.rsp"
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

# Backward compatible mapping:
# Default is container database (CDB). If CONTAINER_DATABASE=false => NON_CDB=true.
if [ -n "${CONTAINER_DATABASE}" ]; then
  if [ "${CONTAINER_DATABASE}" = "false" ]; then
    NON_CDB="true"
  else
    NON_CDB="false"
  fi
else
  NON_CDB="${NON_CDB:-false}"
fi

# If NON_CDB requested, force dbca response file to create Non-CDB (no PDB section)
if [ "${NON_CDB}" = "true" ]; then
  echo "NON_CDB=true -> updating dbca.rsp for Non-CDB creation"

  # Force non-CDB
  sed -i -E "s/^[[:space:]]*createAsContainerDatabase=.*/createAsContainerDatabase=false/g" "$ORACLE_BASE"/dbca.rsp


  # Remove PDB-related entries (otherwise DBCA will still create PDBs)
  sed -i -e "/^createPDBDatabase=/d" \
         -e "/^numberOfPDBs=/d" \
         -e "/^pdbName=/d" \
         -e "/^pdbAdminUserName=/d" \
         -e "/^pdbAdminPassword=/d" \
         "$ORACLE_BASE"/dbca.rsp
fi


# Create network related config files (sqlnet.ora, listener.ora)
setupNetworkConfig;

# Directory for storing archive logs
export ARCHIVELOG_DIR=$ORACLE_BASE/oradata/$ORACLE_SID/$ARCHIVELOG_DIR_NAME

# Start LISTENER and run DBCA
# Ignoring shell check so as to treat DBCA_CRED_OPTIONS as separate args to dbca
# shellcheck disable=SC2086
lsnrctl start
if ! dbca -silent -createDatabase \
  -enableArchive "$ENABLE_ARCHIVELOG" \
  -archiveLogDest "$ARCHIVELOG_DIR" \
  ${DBCA_CRED_OPTIONS} \
  ${DBCA_RECOVERY_CONFIG_OPTIONS} \
  -responseFile "$ORACLE_BASE"/dbca.rsp; then
    cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log ||
      cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
    exit 1
fi

configurePrimaryTDE;

# Setup tnsnames.ora after DBCA command execution, otherwise tnsnames gets overwritten by DBCA
setupTnsnames;

# Remove second control file, fix local_listener, make PDB auto open, enable EM global port
# Create externally mapped oracle user for health check
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   ALTER SYSTEM SET local_listener='';
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);

   ALTER SESSION SET "_oracle_script" = true;
   CREATE USER OPS\$oracle IDENTIFIED EXTERNALLY;
   GRANT CREATE SESSION TO OPS\$oracle;
   GRANT SELECT ON sys.v_\$database TO OPS\$oracle;

   DECLARE
     v_cdb VARCHAR2(3);
   BEGIN
     SELECT cdb INTO v_cdb FROM v\$database;

     IF v_cdb = 'YES' THEN
       EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE';
       EXECUTE IMMEDIATE 'GRANT SELECT ON sys.v_\$pdbs TO OPS\$oracle';
       EXECUTE IMMEDIATE 'ALTER USER OPS\$oracle SET container_data=all for sys.v_\$pdbs container = current';
     END IF;
   END;
   /
   exit;
EOF

# Remove temporary response file
rm "$ORACLE_BASE"/dbca.rsp
