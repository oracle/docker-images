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
TNS_ALIAS_HELPER="${TNS_ALIAS_HELPER:-${SCRIPT_BASE_DIR}/${MANAGE_TNS_ALIASES:-manageTnsAliases.sh}}"
if [ -f "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE" ]; then
  # shellcheck source=/dev/null
  . "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE"
else
  echo "ERROR: Missing required TDE helper: ${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE. Exiting..."
  exit 1
fi

function upsert_local_tns_alias {
  local tns_file="$1"
  local alias_name="$2"
  local service_name="$3"

  # In Kubernetes/operator flow, SVC_HOST/SVC_PORT gives the stable reachable service.
  # In podman/script flow, SVC_HOST is usually empty, so fallback keeps old/local behavior.
  local tns_host="${SVC_HOST:-${ORACLE_HOSTNAME:-0.0.0.0}}"
  local tns_port="${SVC_PORT:-1521}"

  if [ -x "$TNS_ALIAS_HELPER" ]; then
    "$TNS_ALIAS_HELPER" \
      --file "$tns_file" \
      --alias "$alias_name" \
      --upsert \
      --host "$tns_host" \
      --port "$tns_port" \
      --service "$service_name" \
      --protocol "TCP" \
      --strict-dedupe
    return
  fi

  if ! grep -Eq "^[[:space:]]*${alias_name}[[:space:]]*=" "$tns_file" 2>/dev/null; then
    cat >> "$tns_file" <<EOF

${alias_name}=
(DESCRIPTION =
  (ADDRESS = (PROTOCOL = TCP)(HOST = ${tns_host})(PORT = ${tns_port}))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = ${service_name})
  )
)
EOF
  fi
}

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
 # Idempotently ensure the local PDB alias without overwriting other aliases.
  upsert_local_tns_alias "$ORACLE_HOME"/network/admin/tnsnames.ora "$ORACLE_PDB" "$ORACLE_PDB"

}

function setupNetworkConfigFREE {
  # sqlnet.ora
  echo "NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)
DISABLE_OOB=ON
SQLNET.EXPIRE_TIME=3" > "$ORACLE_HOME"/network/admin/sqlnet.ora

# TNS Names.ora
  upsert_local_tns_alias "$ORACLE_HOME"/network/admin/tnsnames.ora "FREEPDB1" "FREEPDB1"
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

############## Prepare standby TDE wallet from zip artifact ##############
function prepareStandbyTDEWalletFromZip {
  TDE_WALLET_ROOT="${TDE_WALLET_ROOT:-/opt/oracle/oradata/dbconfig/${ORACLE_SID}/tdewallet}"
  STANDBY_TDE_SOURCE_ROOT="${STANDBY_TDE_SOURCE_ROOT:-/tmp/primary-tde-source}"

  local standby_wallet_zip="${STANDBY_TDE_WALLET_ZIP_PATH:-}"

  # The operator also sets ORACLE_TDE_SECRET_FILE to the password mount.
  # Point it to the standby ZIP because the helper validates this variable.
  ORACLE_TDE_SECRET_FILE="${standby_wallet_zip}"
  export ORACLE_TDE_SECRET_FILE

  if ! tde_require_standby_wallet_zip "${standby_wallet_zip}"; then
    exit 1
  fi

  rm -rf "${STANDBY_TDE_SOURCE_ROOT}"
  mkdir -p "${STANDBY_TDE_SOURCE_ROOT}"

  unzip -oq "${standby_wallet_zip}" -d "${STANDBY_TDE_SOURCE_ROOT}"

  if [[ ! -f "${STANDBY_TDE_SOURCE_ROOT}/tde/ewallet.p12" ]]; then
    echo "ERROR: Primary TDE wallet not found under ${STANDBY_TDE_SOURCE_ROOT}/tde. Exiting..."
    exit 1
  fi

  find "${STANDBY_TDE_SOURCE_ROOT}" -type d -exec chmod 700 {} \; || true
  find "${STANDBY_TDE_SOURCE_ROOT}" -type f -exec chmod 600 {} \; || true

  mkdir -p "${TDE_WALLET_ROOT}"
  rm -rf "${TDE_WALLET_ROOT}/tde"

  export TDE_WALLET_ROOT
  export STANDBY_TDE_SOURCE_ROOT

  echo "Primary TDE wallet prepared under ${STANDBY_TDE_SOURCE_ROOT}"
  echo "Standby TDE wallet destination is ${TDE_WALLET_ROOT}"
}

############## Patch DBCA-generated standby PFILE for TDE ##############
function patchStandbyTDEPfileWhileDBCARuns {
  local dbca_pid="$1"
  local pfile="${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora"
  local patch_count=0

  echo "Watching DBCA-generated PFILE for TDE configuration: ${pfile}"

  while kill -0 "${dbca_pid}" 2>/dev/null; do
    if [[ -f "${pfile}" ]] &&
       grep -qE \
         '^[[:space:]]*tde_configuration[[:space:]]*=[[:space:]]*KEYSTORE_CONFIGURATION=FILE[[:space:]]*$' \
         "${pfile}"; then

      sed -i \
        "s|^\([[:space:]]*tde_configuration[[:space:]]*=[[:space:]]*\)KEYSTORE_CONFIGURATION=FILE[[:space:]]*$|\1'KEYSTORE_CONFIGURATION=FILE'|" \
        "${pfile}"

      patch_count=$((patch_count + 1))
      echo "Patched DBCA-generated TDE parameter in ${pfile}; count=${patch_count}"
    fi

    sleep 0.02
  done

  # Final pass in case DBCA rewrites the file immediately before exiting.
  if [[ -f "${pfile}" ]]; then
    sed -i \
      "s|^\([[:space:]]*tde_configuration[[:space:]]*=[[:space:]]*\)KEYSTORE_CONFIGURATION=FILE[[:space:]]*$|\1'KEYSTORE_CONFIGURATION=FILE'|" \
      "${pfile}"
  fi

  echo "Standby TDE PFILE watcher finished; patches=${patch_count}"
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

has_dbca_credential_wallet() {
  [ -n "${WALLET_DIR:-}" ] && [ -f "${WALLET_DIR}/ewallet.p12" ]
}

require_primary_sys_auth() {
  if has_dbca_credential_wallet; then
    return 0
  fi

  if [[ -n "${ORACLE_PWD:-}" ]]; then
    return 0
  fi

  echo "ERROR: Please provide primary SYS authentication either through ORACLE_PWD or a DB credentials wallet mounted at WALLET_DIR. Exiting..."
  exit 1
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Creating Primary database/True Cache for FREE edition
if [ "${ORACLE_SID}" = "FREE" ]; then

  if [ "${TRUE_CACHE}" == "true" ]; then

    require_primary_sys_auth

    # Validation: Check if PRIMARY_DB_CONN_STR is provided or not
    if [[ -z "${PRIMARY_DB_CONN_STR}" ]] || [[ $PRIMARY_DB_CONN_STR != *:*/* ]]; then
      echo "ERROR: Please provide PRIMARY_DB_CONN_STR in <HOST>:<PORT>/<SERVICE_NAME> format to connect with primary database. Exiting..."
      exit 1
    fi

    if [ -n "${TRUE_CACHE_BLOB}" ]; then
      SOURCE_DB_BASED_ARGS="-trueCacheBlobFromSourceDB ${TRUE_CACHE_BLOB}"
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
    fi

    if [[ -z "${TRUEDB_UNIQUE_NAME}" ]]; then
       echo "TRUEDB_UNIQUE_NAME parameter value is NOT passed. This is required for setting up True Cache..exiting.."
       exit 1
    fi
    PRIMARY_DB_NAME=${PRIMARY_DB_NAME:-$(echo "${PRIMARY_DB_CONN_STR}" | cut -d '/' -f 2)}
    dbca -silent -createTrueCacheInstance -dbUniqueName "$TRUEDB_UNIQUE_NAME" -gdbName "$PRIMARY_DB_NAME" -sid "$ORACLE_SID" -sourceDBConnectionString "$PRIMARY_DB_CONN_STR" $SOURCE_DB_BASED_ARGS  ORACLE_HOSTNAME="$ORACLE_HOSTNAME" <<EOF
${ORACLE_PWD}
EOF
    [ $? -eq 0 ] || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log

    # Setup network related configuration
    setupNetworkConfigFREE;

    exit 0
  fi

  # Auto generate ORACLE PWD if not passed on
  export ORACLE_PWD=${ORACLE_PWD:-"$(openssl rand -hex 8)"}

  # Set character set & TDE
  sed -e "s|^CHARSET=.*$|CHARSET=$ORACLE_CHARACTERSET|g" \
      -e "s|^CONFIGURE_TDE=.*$|CONFIGURE_TDE=$CONFIGURE_TDE|g" \
      -e "s|^ENCRYPT_TABLESPACES=.*$|ENCRYPT_TABLESPACES=$ENCRYPT_TABLESPACES|g" \
      /etc/sysconfig/"$CONF_FILE" > /tmp/"$CONF_FILE"
  cat /tmp/"$CONF_FILE" > /etc/sysconfig/"$CONF_FILE"
  rm /tmp/"$CONF_FILE"

  # Creating database for FREE edition
  /etc/init.d/oracle-free-26ai configure << EOF
${ORACLE_PWD}
${ORACLE_PWD}
EOF

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

# Listener/service port. Operator sets SVC_PORT; default to 1521 for podman/container flow.
export SVC_PORT=${SVC_PORT:-1521}

# Setting up file creation mask for newly created files (dbca response templates)
umask 177

# Checking if only one of INIT_SGA_SIZE & INIT_PGA_SIZE is provided by the user
if [[ "${INIT_SGA_SIZE}" != "" && "${INIT_PGA_SIZE}" == "" ]] || [[ "${INIT_SGA_SIZE}" == "" && "${INIT_PGA_SIZE}" != "" ]]; then
   echo "ERROR: Provide both the values, INIT_SGA_SIZE and INIT_PGA_SIZE or neither of them. Exiting.";
   exit 1;
fi;

# Load mounted password files when the entrypoint has not exported them.
if [[ -z "${ORACLE_PWD:-}" && -r /run/secrets/oracle_pwd ]]; then
  ORACLE_PWD="$(cat /run/secrets/oracle_pwd)"
  export ORACLE_PWD
fi

if [[ -z "${TDE_WALLET_PWD:-}" && -r /run/secrets/tde_wallet_pwd ]]; then
  TDE_WALLET_PWD="$(cat /run/secrets/tde_wallet_pwd)"
  export TDE_WALLET_PWD
fi

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

# Keep DBCA create/clone flows aligned with the startup-level datapatch toggle.
DBCA_DATAPATCH_OPTIONS=""
if [[ "${SKIP_DATAPATCH:-false}" == "true" ]]; then
  DBCA_DATAPATCH_OPTIONS="-skipDatapatch"
fi

# Automatically enable TDE for standby creation when a wallet zip is supplied.
# This avoids requiring a separate TDE_ENABLED environment variable.
if [[ "${STANDBY_DB}" == "true" &&
      -n "${STANDBY_TDE_WALLET_ZIP_PATH:-}" ]]; then
  TDE_ENABLED="true"
  export TDE_ENABLED
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
  PRIMARY_DB_NAME=${PRIMARY_DB_NAME:-$(echo "${PRIMARY_DB_CONN_STR}" | cut -d '/' -f 2)}

  # Creating the database using the dbca command
  if [ "${STANDBY_DB}" = "true" ]; then
      TDE_DBCA_INIT_PARAMS=()
      TDE_DBCA_DUPLICATE_OPTIONS=()
      STANDBY_TDE_PATCH_PID=""

      if [[ "${TDE_ENABLED}" == "true" ]]; then
          prepareStandbyTDEWalletFromZip

          if [[ -z "${TDE_WALLET_PWD:-}" ]]; then
              echo "ERROR: TDE_WALLET_PWD is required for TDE standby duplication. Exiting..."
              exit 1
          fi

          if [[ ! -f "${STANDBY_TDE_SOURCE_ROOT}/tde/ewallet.p12" ]]; then
              echo "ERROR: Primary TDE wallet not found at ${STANDBY_TDE_SOURCE_ROOT}/tde/ewallet.p12. Exiting..."
              exit 1
          fi

          TDE_DBCA_INIT_PARAMS=(
            -initParams
            "wallet_root=${TDE_WALLET_ROOT}"
          )

          TDE_DBCA_DUPLICATE_OPTIONS=(
            -primaryDBTdeWallet
            "${STANDBY_TDE_SOURCE_ROOT}/tde"
            -sourceTdeWalletPassword
            "${TDE_WALLET_PWD}"
            -tdeWalletRoot
            "${TDE_WALLET_ROOT}"
          )
      fi

      # In operator flow, ORACLE_HOSTNAME can be raw pod IP like 10.244.x.x.
      # DBCA standby duplicate parses that badly and may generate 0.0.0.10.
      # Use container hostname only when ORACLE_HOSTNAME is an IP.
      if [[ "${ORACLE_HOSTNAME:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] &&
        [[ -n "${HOSTNAME:-}" ]]; then
          export ORACLE_HOSTNAME="${HOSTNAME}"
      fi

      if [[ "${TDE_ENABLED}" == "true" ]]; then
          # TDE standby only: run DBCA in the background so the generated
          # PFILE can be corrected before each auxiliary instance startup.
          # DBCA 23.26 still reads the remote SYS password from stdin.
          # shellcheck disable=SC2086
          printf '%s\n' "${ORACLE_PWD}" |
          dbca -silent -createDuplicateDB \
            -gdbName "$PRIMARY_DB_NAME" \
            -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" \
            -sysPassword "${ORACLE_PWD}" \
            ${DBCA_RECOVERY_CONFIG_OPTIONS} \
            ${DBCA_DATAPATCH_OPTIONS} \
            "${TDE_DBCA_INIT_PARAMS[@]}" \
            "${TDE_DBCA_DUPLICATE_OPTIONS[@]}" \
            -sid "$ORACLE_SID" \
            -createAsStandby \
            -createListener LISTENER:"${SVC_PORT}" \
            -datafileDestination "$ORACLE_BASE/oradata" \
            -useOMF true \
            -dbUniquename "$ORACLE_SID" \
            ORACLE_HOSTNAME="$ORACLE_HOSTNAME" &

          DBCA_PID=$!

          patchStandbyTDEPfileWhileDBCARuns "${DBCA_PID}" &
          STANDBY_TDE_PATCH_PID=$!

          if wait "${DBCA_PID}"; then
              DBCA_RC=0
          else
              DBCA_RC=$?
          fi

          wait "${STANDBY_TDE_PATCH_PID}" || true

          if [[ "${DBCA_RC}" -ne 0 ]]; then
              cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}/${ORACLE_SID}.log" ||
                cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}.log"

              exit "${DBCA_RC}"
          fi

          configureStandbyTDEParameters
          rm -rf "${STANDBY_TDE_SOURCE_ROOT}"
      else
          # Existing non-TDE standby flow remains unchanged.
          if [[ -n "${ORACLE_PWD:-}" ]]; then
              # shellcheck disable=SC2086
              if ! dbca -silent -createDuplicateDB \
                -gdbName "$PRIMARY_DB_NAME" \
                -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" \
                ${DBCA_CRED_OPTIONS} \
                ${DBCA_RECOVERY_CONFIG_OPTIONS} \
                ${DBCA_DATAPATCH_OPTIONS} \
                -sid "$ORACLE_SID" \
                -createAsStandby \
                -createListener LISTENER:"${SVC_PORT}" \
                -datafileDestination "$ORACLE_BASE/oradata" \
                -useOMF true \
                -dbUniquename "$ORACLE_SID" \
                ORACLE_HOSTNAME="$ORACLE_HOSTNAME" \
                <<< "${ORACLE_PWD}"; then

                  cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}/${ORACLE_SID}.log" ||
                    cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}.log"

                  exit 1
              fi
          else
              # shellcheck disable=SC2086
              if ! dbca -silent -createDuplicateDB \
                -gdbName "$PRIMARY_DB_NAME" \
                -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" \
                ${DBCA_CRED_OPTIONS} \
                ${DBCA_RECOVERY_CONFIG_OPTIONS} \
                ${DBCA_DATAPATCH_OPTIONS} \
                -sid "$ORACLE_SID" \
                -createAsStandby \
                -createListener LISTENER:"${SVC_PORT}" \
                -datafileDestination "$ORACLE_BASE/oradata" \
                -useOMF true \
                -dbUniquename "$ORACLE_SID" \
                ORACLE_HOSTNAME="$ORACLE_HOSTNAME"; then

                  cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}/${ORACLE_SID}.log" ||
                    cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}.log"

                  exit 1
              fi
          fi
      fi

      applyStandbyOpenMode
  elif [ "${CLONE_DB}" = "true" ]; then
    # Creating clone database
    # Wait until the clone service hostname is resolvable before DBCA starts.
    for attempt in $(seq 1 60); do
      if getent hosts "${ORACLE_HOSTNAME}" >/dev/null 2>&1; then
        break
      fi

      if [ "${attempt}" -eq 60 ]; then
        echo "ERROR: Unable to resolve clone hostname ${ORACLE_HOSTNAME}. Exiting..."
        exit 1
      fi

      sleep 2
    done

    printf '%s\n' "${ORACLE_PWD}" |
    dbca -silent -createDuplicateDB \
      -gdbName "$ORACLE_SID" \
      -primaryDBConnectionString "$PRIMARY_DB_CONN_STR" \
      -sysPassword "${ORACLE_PWD}" \
      ${DBCA_RECOVERY_CONFIG_OPTIONS} \
      ${DBCA_DATAPATCH_OPTIONS} \
      -sid "$ORACLE_SID" \
      -databaseConfigType SINGLE \
      -datafileDestination "$ORACLE_BASE/oradata" \
      -useOMF true \
      -dbUniquename "$ORACLE_SID" \
      ORACLE_HOSTNAME="$ORACLE_HOSTNAME" ||
    cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}/${ORACLE_SID}.log" ||
    cat "/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}.log"
  elif  [ "$TRUE_CACHE" = "true" ]; then
      require_primary_sys_auth
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

            if [[ -z "${TRUEDB_UNIQUE_NAME}" ]]; then
               echo "TRUEDB_UNIQUE_NAME parameter value is NOT passed. This is required for setting up True Cache..exiting.."
               exit 1
            fi
	    dbca -silent -createTrueCacheInstance -dbUniqueName "$TRUEDB_UNIQUE_NAME" -gdbName "$PRIMARY_DB_NAME" -sid "$ORACLE_SID" -sourceDBConnectionString "$PRIMARY_DB_CONN_STR" ${DBCA_CRED_OPTIONS} ${DBCA_DATAPATCH_OPTIONS} $SOURCE_DB_BASED_ARGS $SGA_TARGET_IN_MB $PGA_AGGREGATE_TARGET_IN_MB ORACLE_HOSTNAME="$ORACLE_HOSTNAME" <<EOF
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
DBCA_RSP_TEMPLATE="${SCRIPT_BASE_DIR:-$ORACLE_BASE}/${CONFIG_RSP}"
if [ ! -f "${DBCA_RSP_TEMPLATE}" ]; then
  DBCA_RSP_TEMPLATE="${ORACLE_BASE}/${CONFIG_RSP}"
fi
if [ ! -f "${DBCA_RSP_TEMPLATE}" ]; then
  echo "Response file template ${CONFIG_RSP} not found in ${ORACLE_BASE} or ${SCRIPT_BASE_DIR:-unset}." >&2
  exit 1
fi
cp "${DBCA_RSP_TEMPLATE}" "${ORACLE_BASE}/dbca.rsp"
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

# TDE can be enabled explicitly and configured for DBCA.
TDE_ENABLED="${TDE_ENABLED:-false}"
# Keep primary createDatabase on the last-known-good wallet layout.
TDE_WALLET_ROOT="${TDE_WALLET_ROOT:-/opt/oracle/oradata/${ORACLE_SID}/tdewallet}"
DBCA_TDE_CONFIG_OPTIONS=""
if [[ "${TDE_ENABLED}" == "true" ]]; then
  if [ -n "${ORACLE_EDITION}" ] && [ "${ORACLE_EDITION^^}" != "ENTERPRISE" ]; then
    echo "Transparent Data Encryption (TDE) is supported only for Enterprise Edition of database. Exiting...";
    exit 1;
  fi;

  if [[ -z "${TDE_WALLET_PWD}" ]]; then
    if ! tde_require_primary_password; then
      exit 1
    fi
  fi

  if [[ ! -d "${TDE_WALLET_ROOT}" ]]; then
    mkdir -p "${TDE_WALLET_ROOT}"
  fi

  DBCA_TDE_CONFIG_OPTIONS="-configureTDE true -tdeWalletRoot ${TDE_WALLET_ROOT} -tdeWalletLoginType AUTO -encryptTablespaces ALL"
fi

# Run DBCA
if [[ "${TDE_ENABLED}" == "true" ]]; then
  dbca -silent -createDatabase -createListener LISTENER:1521 -enableArchive "$ENABLE_ARCHIVELOG" -archiveLogDest "$ARCHIVELOG_DIR" -enableForceLogging "$ENABLE_FORCE_LOGGING" ${DBCA_CRED_OPTIONS} ${DBCA_RECOVERY_CONFIG_OPTIONS} ${DBCA_DATAPATCH_OPTIONS} -datafileDestination $ORACLE_BASE/oradata -useOMF true -responseFile "$ORACLE_BASE"/dbca.rsp ${DBCA_TDE_CONFIG_OPTIONS} <<< "${TDE_WALLET_PWD}" || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
else
  dbca -silent -createDatabase -createListener LISTENER:1521 -enableArchive "$ENABLE_ARCHIVELOG" -archiveLogDest "$ARCHIVELOG_DIR" -enableForceLogging "$ENABLE_FORCE_LOGGING" ${DBCA_CRED_OPTIONS} ${DBCA_RECOVERY_CONFIG_OPTIONS} ${DBCA_DATAPATCH_OPTIONS} -datafileDestination $ORACLE_BASE/oradata -useOMF true -responseFile "$ORACLE_BASE"/dbca.rsp || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID"/"$ORACLE_SID".log || cat /opt/oracle/cfgtoollogs/dbca/"$ORACLE_SID".log
fi

# Create/update network related config files (sqlnet.ora, listener.ora)
setupNetworkConfig;

# Setting up database
dbSetupSQL;

# Remove temporary response file
rm "$ORACLE_BASE"/dbca.rsp
