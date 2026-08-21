#!/bin/bash

# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: Feb, 2026
# Author: paramdeep.saini@oracle.com
# Description: Creates an Oracle Database using backup available on Object store:
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#####################

set -euo pipefail

# Write UTC timestamped log messages to stderr.
# Keep restore progress and failures in a consistent format.
function log() { printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >&2; }
# Log a fatal error and abort immediately.
# Keep guard clauses short when restore preconditions fail.
function die() { log "ERROR: $*"; exit 1; }

# Clear sensitive password variables before the shell exits.
# Reduce secret exposure in subshells, traces, and crash output.
function cleanup_secrets() {
  unset ORACLE_PWD SOURCE_DB_WALLET_PWD DECRYPT_PWD
}
trap cleanup_secrets EXIT

# Verify required database and archive tools exist before restore starts.
# Stop early when the image is missing a runtime dependency.
function validate_runtime_tools() {
  local missing=0
  local cmd
  for cmd in sqlplus rman orapwd nid unzip tar gzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "ERROR: required command not found: $cmd"
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

# Resolve the effective restore source mode from env and legacy flags.
# Default to objectstore when no filesystem override is set.
function get_restore_source_type() {
  local mode="${RESTORE_SOURCE_TYPE:-}"
  mode="$(echo "${mode}" | tr '[:upper:]' '[:lower:]' | xargs)"
  if [[ "${mode}" == "filesystem" || "${mode}" == "objectstore" ]]; then
    echo "${mode}"
    return
  fi
  if [[ -n "${CLONE_DB_FROM_FS_BACKUP:-}" ]]; then
    echo "filesystem"
    return
  fi
  echo "objectstore"
}

# Return success when the selected restore mode is filesystem based.
# Keep branching logic readable at call sites.
function is_fs_restore() {
  [[ "${RESTORE_SOURCE_TYPE_EFFECTIVE}" == "filesystem" ]]
}

# Return success when the selected restore mode is object-store based.
# Keep branching logic readable at call sites.
function is_object_restore() {
  [[ "${RESTORE_SOURCE_TYPE_EFFECTIVE}" == "objectstore" ]]
}

# Create the restore working directories before unpacking wallets or backups.
# Add object-store specific directories only for OPC-based restores.
function create_dirs() {
local dirs=("$ORADATA_DIR" "$WALLET_ROOT")
if is_object_restore; then
  dirs+=("$OPC_LIB_DIR" "$CONFIG_PARENT")
fi
for DIR in "${dirs[@]}"; do
    if [ ! -d "$DIR" ]; then
        log "Directory $DIR does not exist. Creating it..."
        mkdir -p "$DIR"

        # Verify creation was successful
        if [ $? -ne 0 ]; then
            log "ERROR: Failed to create $DIR. Check permissions."
            exit 1
        fi
    else
        log "Directory $DIR already exists."
    fi
done
}

# Install or reuse the OCI backup module for object-store restores.
# Skip the installer entirely for filesystem-based restores.
function install_opc() {
  if ! is_object_restore; then
    log "Filesystem restore selected. Skipping OPC installer."
    return 0
  fi

  if [[ -f "$OPC_LIB_DIR/libopc.so" && -f "$BACKUP_CONFIG_FILE" && "$FORCE_OPC_REINSTALL" != "true" ]]; then
    log "OPC already installed (libopc.so + opc_config found). Skipping (use --force-opc-reinstall to override)."
    return 0
  fi

  local tmpdir
  tmpdir="$(mktemp -d "$OPC_LOG_DIR/opc_installer.XXXXXX")"
  trap 'rm -rf "$tmpdir"' RETURN

  log "Unzipping OPC installer to $tmpdir"
  unzip -q "$OPC_INSTALL_ZIP" -d "$tmpdir"

  local opc_dir="$tmpdir/oci_installer"
  [[ -d "$opc_dir" ]] || die "Expected installer directory not found: $opc_dir"

  local jar="$opc_dir/oci_install.jar"
  [[ -f "$jar" ]] || die "Installer jar not found: $jar"

  log "Running OPC installer..."
  $JAVA_BIN -jar $tmpdir/oci_installer/oci_install.jar \
   -host "$OPC_HOST" \
   -pvtKeyFile "$PVT_KEY_PATH" \
   -pubFingerPrint "$FINGERPRINT" \
   -uOCID "$USER_OCID" \
   -tOCID "$TENANCY_OCID" \
   -bucket "$BUCKET_NAME" \
   -walletDir "$OPC_WALLET_DIR" \
   -libDir "$OPC_LIB_DIR" \
   -cOCID "$COMPARTMENT_OCID" \
   -configFile "$BACKUP_CONFIG_FILE"

  [[ -f "$BACKUP_CONFIG_FILE" ]] || die "OPC configfile not created: $BACKUP_CONFIG_FILE"
  [[ -f "$OPC_LIB_DIR/libopc.so" ]] || die "OPC library not found after install: $OPC_LIB_DIR/libopc.so"
  log "OPC install completed: $OPC_LIB_DIR/libopc.so"
}

# Extract the source wallet archive into WALLET_ROOT when provided.
# Validate the tar.gz input before unpacking anything on disk.
function unzipwallet() {
# Check SOURCE_DB_WALLET env var; if set, verify file exists and unzip into ORA_DATA_DIR
if [[ -n "${SOURCE_DB_WALLET:-}" ]]; then
  if [[ -z "${WALLET_ROOT:-}" ]]; then
    log "ERROR: ORADATA_DIR is not set, cannot unzip SOURCE_DB_WALLET."
    exit 1
  fi
  if [[ ! -f "$SOURCE_DB_WALLET" ]]; then
    log "ERROR: SOURCE_DB_WALLET is set but file does not exist: $SOURCE_DB_WALLET"
    exit 1
  fi
# Validate tar.gz
if ! gzip -t "$SOURCE_DB_WALLET" >/dev/null 2>&1; then
  log "ERROR: Not a valid gzip file: $SOURCE_DB_WALLET"
  exit 1
fi
if ! tar -tzf "$SOURCE_DB_WALLET" >/dev/null 2>&1; then
  log "ERROR: Not a valid tar.gz file: $SOURCE_DB_WALLET"
  exit 1
fi

# Extract tar.gz into target directory
tar -xzf "$SOURCE_DB_WALLET" -C "$WALLET_ROOT" || {
  log "ERROR: Failed to extract $SOURCE_DB_WALLET into $WALLET_ROOT"
  exit 1
}
  # Optional: restrict permissions on extracted wallet files
  chmod -R go-rwx "$WALLET_ROOT" 2>/dev/null || true
fi
}

# Generate a minimal init.ora for the bootstrap NOMOUNT startup.
# Add wallet parameters only when a source wallet is being restored.
function generatepfile() {
  if [[ -z "${OPC_LOG_DIR:-}" ]]; then
    log "ERROR: OPC_LOG_DIR is not set"
    return 1
  fi
  if [[ -z "${ORACLE_SID:-}" ]]; then
    log "ERROR: ORACLE_SID is not set"
    return 1
  fi
  if [[ -z "${WALLET_ROOT:-}" ]]; then
    log "ERROR: WALLET_ROOT is not set"
    return 1
  fi
  local pfile="$OPC_LOG_DIR/init${ORACLE_SID}.ora"

  umask 077
  {
    echo "db_name='${ORACLE_SID}'"
    if [[ -n "${SOURCE_DB_WALLET:-}" ]]; then
      echo "wallet_root='${WALLET_ROOT}'"
      echo "tde_configuration='keystore_configuration=file'"
    fi
  } > "$pfile" || { log "ERROR: Failed to write pfile: $pfile"; return 1; }

  chmod 600 "$pfile" 2>/dev/null || true

  # Print the path (handy for callers)
  log "$pfile"
}

# Round-trip the SPFILE through a PFILE so parameters can be deleted or set.
# Recreate the SPFILE after the requested edits are applied.
function modifyspfile() {
local spfile=$1
local pfile=$2
shift 2

local delete_list=()
local param_list=()

mode="delete"

for arg in "$@"; do
    case "$arg" in
        --delete)
            mode="delete"
            continue
            ;;
        --set)
            mode="set"
            continue
            ;;
    esac

    if [[ "$mode" == "delete" ]]; then
        delete_list+=("$arg")
    else
        param_list+=("$arg")
    fi
done
    #Create the PFILE from the SPFILE
    log "Creating PFILE from SPFILE..."
    sqlplus -s / as sysdba <<EOF
    CREATE PFILE='$pfile' FROM SPFILE='$spfile';
EOF

    if [ $? -ne 0 ]; then
        log "Error: Failed to create PFILE from SPFILE."
        return 1
    fi

    #Delete specified parameters from the PFILE
    for delete_param in "${delete_list[@]}"; do
        log "Deleting parameter: $delete_param"
        #sed -i "/^$delete_param/d" "$pfile"
        sed -E -i "/$delete_param/d" "$pfile"
    done

    #Modify specified parameters in the PFILE
    for param in "${param_list[@]}"; do
        # Split the parameter into name and value
        param_name="${param%%=*}"
        param_value="${param#*=}"

        # Handle global parameters that start with *.
        if [[ "$param_name" == *.* ]]; then
            # Global parameter (e.g., *.db_block_size)
            log "Modifying global parameter: $param_name to $param_value"
            sed -i "s|^\*\.${param_name}=.*|*.${param_name}=${param_value}|" "$pfile"
        else
            # Regular parameter (without *)
            if grep -q "^$param_name=" "$pfile"; then
                log "Modifying parameter: $param_name to $param_value"
                # Replace the old value with the new value
                sed -i "s|^${param_name}=.*|${param_name}=${param_value}|" "$pfile"
            else
                log "Adding new parameter: $param_name=$param_value"
                # If the parameter doesn't exist, add it to the end of the file
                echo "$param_name=$param_value" >> "$pfile"
            fi
        fi
    done

    log "PFILE modified: $pfile"
    log "Creating SPFILE from PFILE..."
	    sqlplus -s / as sysdba <<EOF
    CREATE SPFILE='$spfile' FROM PFILE='$pfile';
EOF
mv "$pfile" /tmp/

}

# Open the TDE wallet with the supplied wallet password when available.
# Temporarily disable xtrace so secrets are not echoed.
function openwallet() {
  if [[ -n "${SOURCE_DB_WALLET:-}" && -n "${SOURCE_DB_WALLET_PWD:-}" ]]; then
    local xtrace_was_on=0
    case "$-" in *x*) xtrace_was_on=1; set +x;; esac
    "$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<EOF
set echo off feedback on
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "${SOURCE_DB_WALLET_PWD}";
exit
EOF
    if [[ $xtrace_was_on -eq 1 ]]; then set -x; fi
  fi
}

# Open the TDE wallet inside the configured PDB when the database is a CDB.
# Skip the extra step for non-CDB restores or when no wallet password is set.
function openpdbwallet() {
  if [[ -n "${SOURCE_DB_WALLET:-}" && -n "${SOURCE_DB_WALLET_PWD:-}" ]]; then
    local is_cdb

    is_cdb=$("$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<EOF
set heading off pagesize 0 feedback off verify off
SELECT cdb FROM v\$database;
exit
EOF
    )
   
    if [[ "${is_cdb//[[:space:]]/}" == "YES" ]]; then
        local pdb_name="${ORACLE_PDB:-}"
        local xtrace_was_on=0
        case "$-" in *x*) xtrace_was_on=1; set +x;; esac
        "$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<EOF
set echo off feedback on
ALTER SESSION SET CONTAINER="${pdb_name}";
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "${SOURCE_DB_WALLET_PWD}";
exit
EOF
        if [[ $xtrace_was_on -eq 1 ]]; then set -x; fi
    fi
  fi
}

# Start the instance in NOMOUNT using either the generated PFILE or SPFILE.
# Exit with the sqlplus return code when startup fails.
function startupdb() {
local file_type=$1

if [[ "$file_type" == "pfile" ]]; then
  $ORACLE_HOME/bin/sqlplus -s / as sysdba <<SQL
  WHENEVER SQLERROR EXIT SQL.SQLCODE;
  SET ECHO OFF FEEDBACK OFF HEADING OFF VERIFY OFF PAGES 0
  STARTUP NOMOUNT PFILE='${PFILE_PATH}';
  EXIT;
SQL
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "Failed to STARTUP NOMOUNT with PFILE=${PFILE_PATH} (rc=$rc)" >&2
    exit $rc
  fi
elif [[ "$file_type" == "spfile" ]]; then
  $ORACLE_HOME/bin/sqlplus -s / as sysdba <<SQL
  WHENEVER SQLERROR EXIT SQL.SQLCODE;
  SET ECHO OFF FEEDBACK OFF HEADING OFF VERIFY OFF PAGES 0
  STARTUP NOMOUNT;
  EXIT;
SQL
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "Failed to STARTUP NOMOUNT with SPFILE (rc=$rc)" >&2
    exit $rc
  fi
fi
}

# Prepare RMAN channel and catalog clauses for the chosen restore source.
# Switch between SBT/object-store and disk/filesystem restore syntax.
function init_rman_transport_vars() {
  RMAN_CATALOG_CLAUSE=""
  if is_object_restore; then
    local sbt_lib="$OPC_LIB_DIR/libopc.so"
    [[ -f "$sbt_lib" ]] || die "SBT library not found at expected location: $sbt_lib"
    [[ -f "$BACKUP_CONFIG_FILE" ]] || die "OPC config file not found: $BACKUP_CONFIG_FILE"
    RMAN_ALLOCATE_CLAUSE="allocate channel c1 device type sbt PARMS 'SBT_LIBRARY=${sbt_lib}, SBT_PARMS=(OPC_PFILE=${BACKUP_CONFIG_FILE})';"
    RMAN_ALLOCATE_CLAUSE_MAINTENANCE="allocate channel for maintenance device type sbt PARMS 'SBT_LIBRARY=${sbt_lib}, SBT_PARMS=(OPC_PFILE=${BACKUP_CONFIG_FILE})';"
    RMAN_CTRL_AUTOBK_FORMAT="set controlfile autobackup format for device type sbt to '%F';"
  else
    RMAN_ALLOCATE_CLAUSE="allocate channel c1 device type disk;"
    RMAN_ALLOCATE_CLAUSE_MAINTENANCE="allocate channel for maintenance device type disk;"
    RMAN_CTRL_AUTOBK_FORMAT="set controlfile autobackup format for device type disk to '${FS_BACKUP_CATALOG_START_WITH}/%F';"
    RMAN_CATALOG_CLAUSE="catalog start with '${FS_BACKUP_CATALOG_START_WITH}' noprompt;"
  fi
}


# Restore the SPFILE from autobackup with the resolved RMAN transport settings.
# Include decryption when needed and ensure controlfile directories exist first.
function rmanrestorespfile() {
  init_rman_transport_vars

# Optional RMAN decryption clause (for encrypted backups)
DECRYPTION_CLAUSE=""
if [[ -n "${DECRYPT_PWD:-}" ]]; then
  DECRYPTION_CLAUSE="set decryption identified by '${DECRYPT_PWD}';"
fi
  # Ensure controlfile dir exists (RMAN/Oracle may not create intermediate dirs)
  mkdir -p "$ORADATA_DIR/CONTROLFILE" || true

  local rman_cmd
  rman_cmd="$(mktemp $LOG_DIR/restore_spfile.XXXXXX.rman)"
  trap 'rm -f "$rman_cmd"' RETURN
  chmod 600 "$rman_cmd"

  log "Generating RMAN script: $rman_cmd"

  # NOTE: please do NOT `set echo on;` to reduce risk of secrets showing up in logs.
cat > "$rman_cmd" <<RMAN_EOF
set dbid ${DBID};

${DECRYPTION_CLAUSE}

${RMAN_CTRL_AUTOBK_FORMAT}

run {
  ${RMAN_ALLOCATE_CLAUSE}
  restore spfile from autobackup maxdays 60;
}

shutdown immediate;
RMAN_EOF

log "RMAN parameters: DBID=${DBID}, SOURCE_TYPE=${RESTORE_SOURCE_TYPE_EFFECTIVE}, PFILE=${PFILE_PATH}, ORADATA_DIR=${ORADATA_DIR}"
rman target / cmdfile="$rman_cmd"
}

# Validate that a controlfile autobackup is reachable before restoring it.
# Reuse the same transport and decryption settings as the real restore path.
function rmanvalidatecontrolfileautobackup() {
init_rman_transport_vars
local rman_cmd
rman_cmd="$(mktemp $LOG_DIR/validate_controlfile.XXXXXX.rman)"
trap 'rm -f "$rman_cmd"' RETURN
chmod 600 "$rman_cmd"

DECRYPTION_CLAUSE=""
if [[ -n "${DECRYPT_PWD:-}" ]]; then
  DECRYPTION_CLAUSE="set decryption identified by '${DECRYPT_PWD}';"
fi

cat > "$rman_cmd" <<RMAN_EOF
set dbid ${DBID};
${DECRYPTION_CLAUSE}
${RMAN_CTRL_AUTOBK_FORMAT}
run {
  ${RMAN_ALLOCATE_CLAUSE}
  restore controlfile from autobackup maxdays 60 validate;
}
RMAN_EOF

log "Validating controlfile autobackup availability before restore..."
rman target / cmdfile="$rman_cmd"
}

# Restore and mount the controlfile from autobackup.
# Share the same transport setup as the SPFILE restore flow.
function rmanrestorecontrolfile() {
init_rman_transport_vars
local rman_cmd
rman_cmd="$(mktemp $LOG_DIR/restore_controlfile.XXXXXX.rman)"
trap 'rm -f "$rman_cmd"' RETURN
chmod 600 "$rman_cmd"

# Optional RMAN decryption clause (for encrypted backups)
DECRYPTION_CLAUSE=""
if [[ -n "${DECRYPT_PWD:-}" ]]; then
  DECRYPTION_CLAUSE="set decryption identified by '${DECRYPT_PWD}';"
fi

cat > "$rman_cmd" <<RMAN_EOF
set dbid ${DBID};

${DECRYPTION_CLAUSE}

${RMAN_CTRL_AUTOBK_FORMAT}

run {
  ${RMAN_ALLOCATE_CLAUSE}
  restore controlfile from autobackup maxdays 60;
  alter database mount;
}
RMAN_EOF

log "RMAN parameters: DBID=${DBID}, SOURCE_TYPE=${RESTORE_SOURCE_TYPE_EFFECTIVE}, PFILE=${PFILE_PATH}, ORADATA_DIR=${ORADATA_DIR}"
rman target / cmdfile="$rman_cmd"
}

# Crosscheck backups and validate the database restore set before recovery.
# Catch missing or unusable backup pieces before the real restore begins.
function rmanvalidatedatabase() {
init_rman_transport_vars
local rman_cmd
rman_cmd="$(mktemp $LOG_DIR/validate_database.XXXXXX.rman)"
trap 'rm -f "$rman_cmd"' RETURN
chmod 600 "$rman_cmd"

DECRYPTION_CLAUSE=""
if [[ -n "${DECRYPT_PWD:-}" ]]; then
  DECRYPTION_CLAUSE="set decryption identified by '${DECRYPT_PWD}';"
fi

cat > "$rman_cmd" <<RMAN_EOF
${DECRYPTION_CLAUSE}
list backup summary;
${RMAN_ALLOCATE_CLAUSE_MAINTENANCE}
crosscheck backup;
release channel;
run {
  ${RMAN_ALLOCATE_CLAUSE}
  ${RMAN_CATALOG_CLAUSE}
  restore database validate;
}
RMAN_EOF

log "Validating database backup sets before restore..."
rman target / cmdfile="$rman_cmd"
}

# Crosscheck and purge expired backup metadata in RMAN.
# Keep the catalog or controlfile metadata consistent before restore.
function rmancrosscheckbackup() {
init_rman_transport_vars
local rman_cmd
rman_cmd="$(mktemp $LOG_DIR/restore_crosscheck_backup.XXXXXX.rman)"
trap 'rm -f "$rman_cmd"' RETURN
chmod 600 "$rman_cmd"
cat > "$rman_cmd" <<RMAN_EOF
RUN {
  ${RMAN_ALLOCATE_CLAUSE}
  ${RMAN_CATALOG_CLAUSE}

  CROSSCHECK BACKUP;
  CROSSCHECK ARCHIVELOG ALL;

  CROSSCHECK BACKUP;
  CROSSCHECK ARCHIVELOG ALL;

  DELETE NOPROMPT EXPIRED BACKUP;
  DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;

  RELEASE CHANNEL c1;
}
  LIST EXPIRED BACKUP;
  LIST EXPIRED ARCHIVELOG ALL;
RMAN_EOF
log "RMAN parameters: DBID=${DBID}, SOURCE_TYPE=${RESTORE_SOURCE_TYPE_EFFECTIVE}, PFILE=${PFILE_PATH}, ORADATA_DIR=${ORADATA_DIR}"
rman target / cmdfile="$rman_cmd"
}

check_database_flashback() {
# code to check database flashback status
FLASHBACK_CHECK=$($ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SELECT FLASHBACK_ON FROM V\$DATABASE;
EXIT;
EOF
)

FLASHBACK_ACTION=""
if [[ "$FLASHBACK_CHECK" == *"YES"* || "$FLASHBACK_CHECK" == *"ORA-38760"* ]]; then
    log "Flashback was ENABLED on source. Target will match."
    FLASHBACK_ACTION="SQL \"ALTER DATABASE FLASHBACK ON\";"
else
    log "Flashback was DISABLED on source."
    FLASHBACK_ACTION=""
fi

# Disable the Flashback Database
$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
WHENEVER SQLERROR CONTINUE;
ALTER DATABASE FLASHBACK OFF;
EXIT;
EOF

}

block_change_tracking() {

# Code to check if BCT enabled
BCT_CHECK=$($ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SELECT CASE
         WHEN EXISTS (SELECT 1 FROM V\$CONTROLFILE_RECORD_SECTION WHERE TYPE = 'BLOCK CHANGE TRACKING')
         THEN (SELECT STATUS FROM V\$BLOCK_CHANGE_TRACKING)
         ELSE 'DISABLED'
       END FROM DUAL;
EXIT;
EOF
)


# Set the clause to re enable BCT post Restore/recover
if [[ "$BCT_CHECK" == *"ENABLED"* ]] || [[ "$BCT_CHECK" == *"ORA-19755"* ]]; then
    log "BCT was ENABLED on the source database. Target will match."
    BCT_TARGET_ACTION="SQL \"ALTER DATABASE ENABLE BLOCK CHANGE TRACKING\";"
else
    log "BCT was DISABLED on the source database. Target will match."
    BCT_TARGET_ACTION=""
fi

# Disable the Block Change Tracking
$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
WHENEVER SQLERROR CONTINUE;
ALTER DATABASE DISABLE BLOCK CHANGE TRACKING;
EXIT;
EOF

}
function rmanrestoredb() {
init_rman_transport_vars
local rman_cmd
rman_cmd="$(mktemp $LOG_DIR/restore_db.XXXXXX.rman)"
trap 'rm -f "$rman_cmd"' RETURN
chmod 600 "$rman_cmd"
# Function for database flashback
check_database_flashback

# Function to check the BCT status
block_change_tracking

  cat > "$rman_cmd" <<RMAN_EOF
  RUN {
    ${RMAN_ALLOCATE_CLAUSE}
    ${RMAN_CATALOG_CLAUSE}

    SET NEWNAME FOR DATABASE TO '${ORADATA_DIR}/%U';
    RESTORE DATABASE;
    SWITCH DATAFILE ALL;
  }

  RUN {
    ${RMAN_ALLOCATE_CLAUSE}
    ${RMAN_CATALOG_CLAUSE}
  RECOVER DATABASE UNTIL available redo;
  ALTER DATABASE OPEN RESETLOGS;

  # Conditionally applies BCT and Flashback only if it existed on the source
  ${BCT_TARGET_ACTION}
  ${FLASHBACK_ACTION}

  # Resetting RMAN snapshot control file configuration to default
  CONFIGURE SNAPSHOT CONTROLFILE NAME CLEAR;
}

RMAN_EOF

log "RMAN parameters: DBID=${DBID}, SOURCE_TYPE=${RESTORE_SOURCE_TYPE_EFFECTIVE}, PFILE=${PFILE_PATH}, ORADATA_DIR=${ORADATA_DIR}"
rman target / cmdfile="$rman_cmd"
}

# Recreate TEMP tablespaces after the cloned database is opened.
# Handle both CDB root and per-PDB tempfiles when needed.
function recreateTempTbs() {
local IS_CDB
local pdb_list

# Check if the database is a CDB
IS_CDB=$($ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
SET PAGES 0 FEED OFF HEAD OFF
SELECT cdb FROM v\$database;
EOF
)

# Only for CDBs
if [ "$IS_CDB" = "YES" ]; then
    echo "CDB - Opening PDBs and preparing PDB\$SEED..."
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
    ALTER PLUGGABLE DATABASE ALL OPEN;
    ALTER PLUGGABLE DATABASE PDB\$SEED CLOSE IMMEDIATE;
    ALTER PLUGGABLE DATABASE PDB\$SEED OPEN READ WRITE;
EOF
    # Get list of containers for the loop
    pdb_list=$($ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
    SET PAGES 0 FEED OFF HEAD OFF
    SELECT name FROM v\$containers;
EOF
)
else
    echo " Non-CDB - Processing single instance..."
    # For Non-CDB, the "container" is effectively the instance itself
    pdb_list="NON-CDB"
fi

# Loop through containers (or single instance)
for pdb in $pdb_list; do
    echo "--- Processing: $pdb ---"

    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
      -- Only switch container if we are in a CDB
      $([ "$IS_CDB" = "YES" ] && echo "ALTER SESSION SET CONTAINER = $pdb;")

      SET FEEDBACK ON SERVEROUTPUT ON
      DECLARE
        v_tbs_name VARCHAR2(128);
      BEGIN
        SELECT property_value INTO v_tbs_name
        FROM database_properties
        WHERE property_name = 'DEFAULT_TEMP_TABLESPACE';

        EXECUTE IMMEDIATE 'ALTER TABLESPACE ' || v_tbs_name ||
                          ' ADD TEMPFILE SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED';

        DBMS_OUTPUT.PUT_LINE('Added tempfile to ' || v_tbs_name);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Note: ' || SQLERRM);
      END;
/
EOF
done

# Cleanup: Only for CDBs
if [ "$IS_CDB" = "YES" ]; then
    echo "Returning PDB\$SEED to Read Only..."
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
      ALTER SESSION SET CONTAINER = CDB\$ROOT;
      ALTER PLUGGABLE DATABASE PDB\$SEED CLOSE IMMEDIATE;
      ALTER PLUGGABLE DATABASE PDB\$SEED OPEN READ ONLY;
EOF
fi

# Verification
echo "Final Verification:"
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
SET PAGES 20 FEEDBACK ON
COL name FOR a70
SELECT con_id, name FROM v\$tempfile ORDER BY con_id;
EOF
}

# Drop existing tempfile entries before rename and resetlogs work.
# Iterate through root and PDB tempfiles when the database is a CDB.
function dropTempFiles() {
# Determine if the database is a CDB
local IS_CDB
local file_list

IS_CDB=$($ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
SET PAGES 0 FEED OFF HEAD OFF
SELECT cdb FROM v\$database;
EOF
)

# Preparation: Only for CDBs
if [ "$IS_CDB" = "YES" ]; then
    echo "CDB Detected - Opening PDBs and preparing PDB\$SEED..."
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
    ALTER PLUGGABLE DATABASE ALL OPEN;
    ALTER PLUGGABLE DATABASE PDB\$SEED CLOSE IMMEDIATE;
    ALTER PLUGGABLE DATABASE PDB\$SEED OPEN READ WRITE;
EOF
else
    echo "Non-CDB - Skipping"
fi

# Get the list of tempfiles
file_list=$($ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
  SET PAGES 0 FEEDBACK OFF HEAD OFF
  SELECT
    CASE
      WHEN '$IS_CDB' = 'NO' THEN 'NON-CDB'
      WHEN con_id = 1 THEN 'CDB\$ROOT'
      WHEN con_id = 2 THEN 'PDB\$SEED'
      ELSE (SELECT name FROM v\$containers c WHERE c.con_id = t.con_id)
    END || ':' || file#
  FROM v\$tempfile t;
EOF
)

# Drop files individually
for entry in $file_list; do
    target_name=$(echo $entry | cut -d: -f1)
    file_no=$(echo $entry | cut -d: -f2)

    echo "Dropping Tempfile $file_no in $target_name..."

    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
      -- Only switch container if it's a CDB
      $([ "$IS_CDB" = "YES" ] && echo "ALTER SESSION SET CONTAINER = $target_name;")
      ALTER DATABASE TEMPFILE $file_no DROP;
EOF
done

# Final Cleanup: Only for CDBs
if [ "$IS_CDB" = "YES" ]; then
    echo "Returning PDB\$SEED to Read Only..."
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
      ALTER SESSION SET CONTAINER = CDB\$ROOT;
      ALTER PLUGGABLE DATABASE PDB\$SEED CLOSE IMMEDIATE;
      ALTER PLUGGABLE DATABASE PDB\$SEED OPEN READ ONLY;
EOF
fi

# Verify
echo "Verification:"
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
SET PAGES 20 FEEDBACK ON
SELECT name FROM v\$tempfile;
EOF
}

# Rename the restored database to NEW_ORACLE_SID and reopen it.
# Refresh spfile, wallet state, password file, and temp tablespaces afterward.
function changedbname() {
 if [[ -n "${SOURCE_DB_NAME:-}" ]]; then
   if [[ "${SOURCE_DB_NAME}" != "${NEW_ORACLE_SID}" ]]; then
      local new_dbname="${NEW_ORACLE_SID:-}"
           log "Renaming database. ORACLE_SID=$SOURCE_DB_NAME ORACLE_HOME=$ORACLE_HOME NEW_DB_NAME=$new_dbname"

    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" << EOF
      set echo off feedback on
      shutdown immediate;
      startup mount;
      exit
EOF

    # Drop the temp files
    #dropTempFiles

    export ORACLE_SID=${SOURCE_DB_NAME}
    printf "Y\n" | nid target=/ dbname=$NEW_ORACLE_SID
      #    nid is interactive; we auto-confirm with "Y".

  #export ORACLE_SID=$NEW_ORACLE_SID

  # Update spfile parameters (db_name/db_unique_name)
  "$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<SQL
    set echo off feedback on
    shutdown immediate;
    startup nomount;
    alter system set db_name='${NEW_ORACLE_SID}' scope=spfile;
    alter system set db_unique_name='${NEW_ORACLE_SID}' scope=spfile;
    shutdown immediate;
    startup mount;
SQL

    # Open the wallet before opening with resetlogs
    openwallet
    openpdbwallet

  "$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<SQL
    alter database open resetlogs;
    col name format a12
    select name, dbid from v\$database;
    shutdown immediate;
    exit
SQL

echo "Copying spfile file to new SID spfile..."
cp -p ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/spfile${NEW_ORACLE_SID}.ora || return 1

export ORACLE_SID=${NEW_ORACLE_SID}
  "$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<SQL
startup mount;
exit
SQL

openwallet
openpdbwallet

 "$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<SQL
alter database open;
exit
SQL

    # Open the PDB
    openpdb

    # Recreate Temp Tablespace
    #recreateTempTbs

  if [[ -f "${ORACLE_HOME}/dbs/orapw${SOURCE_DB_NAME}" ]]; then
    echo "Copying password file to new SID..."
    cp -p "${ORACLE_HOME}/dbs/orapw${SOURCE_DB_NAME}" "${ORACLE_HOME}/dbs/orapw${NEW_ORACLE_SID}" || return 1
  elif [[ -f "${ORACLE_HOME}/dbs/orapw${SOURCE_DB_NAME,,}" ]]; then
    # some systems use lowercase naming
    cp -p "${ORACLE_HOME}/dbs/orapw${SOURCE_DB_NAME,,}" "${ORACLE_HOME}/dbs/orapw${NEW_ORACLE_SID}" || return 1
  else
    echo "WARNING: No password file found for old SID; generating password file."
    generateorapwdfile
  fi
 fi
else
    echo "Generating password file."
    generateorapwdfile
fi

  log "Done. Database renamed/opened. New DB_NAME=${NEW_ORACLE_SID}"
}

# Write a predictable listener.ora for the new SID and start LISTENER.
# Ensure the cloned database can register cleanly after rename.
function createstartlistener() {
  local netadmin="$ORACLE_HOME/network/admin"
  local listener_ora="$netadmin/listener.ora"

  mkdir -p "$netadmin" || return 1

  log "Setting new oracle SID"
  export ORACLE_SID=$NEW_ORACLE_SID

  # Backup existing listener.ora (if any)
  if [[ -f "$listener_ora" ]]; then
    cp -p "$listener_ora" "${listener_ora}.bak.$(date +%Y%m%d%H%M%S)" || return 1
  fi

  # Write a basic listener.ora (overwrite for predictability)
  # SID_LIST ensures the listener knows the instance even before dynamic registration settles.
  export ORACLE_SID=$NEW_ORACLE_SID
  cat > "$listener_ora" <<EOF
LISTENER =
(DESCRIPTION_LIST =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1))
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  )
)

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
EOF

  # Start listener
  log "Starting listener LISTENER on 0.0.0.0:1521 ..."
  "$ORACLE_HOME/bin/lsnrctl" stop  "LISTENER" >/dev/null 2>&1 || true
  "$ORACLE_HOME/bin/lsnrctl" start "LISTENER" || return 1

  # Show status
  "$ORACLE_HOME/bin/lsnrctl" status "LISTENER" || return 1

  log "Listener LISTENER configured at: $listener_ora"
}

# Regenerate local tnsnames.ora and sqlnet.ora for the cloned SID.
# Reset the local TCP connect descriptor under TNS_ADMIN.
function settnsames() {
# Check ORACLE_SID
if [ -z "$ORACLE_SID" ]; then
    echo "ERROR: ORACLE_SID is not set"
    exit 1
fi

# Set variables
HOSTNAME="0.0.0.0"
PORT=1521
TNS_ADMIN=${TNS_ADMIN:-$ORACLE_HOME/network/admin}

TNS_FILE=$TNS_ADMIN/tnsnames.ora
SQLNET_FILE=$TNS_ADMIN/sqlnet.ora

mkdir -p $TNS_ADMIN

echo "Using TNS_ADMIN: $TNS_ADMIN"

# Ensure the file exists so sed doesn't throw rc=2
touch "$TNS_FILE"

# Remove old entry if exists
sed -i.bak "/^${ORACLE_SID} =/,+10d" $TNS_FILE 2>/dev/null

# Add new TNS entry
cat <<EOF >> $TNS_FILE

${ORACLE_SID} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${HOSTNAME})(PORT = ${PORT}))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${ORACLE_SID})
    )
  )
EOF

echo "TNS entry created for $ORACLE_SID"

# Create sqlnet.ora
cat <<EOF > $SQLNET_FILE
NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)
DISABLE_OOB=ON
SQLNET.EXPIRE_TIME=3
EOF

echo "sqlnet.ora configured"

echo "Configuration complete."
echo "Files:"
echo "$TNS_FILE"
echo "$SQLNET_FILE"
}

# Create or replace the SYS password file for the renamed database.
# Reset SYS inside the database to match ORACLE_PWD.
function generateorapwdfile() {
if [[ -n "$ORACLE_PWD" ]]; then

export ORACLE_SID=${NEW_ORACLE_SID}
PWDFILE="${PWDFILE:-$ORACLE_HOME/dbs/orapw$NEW_ORACLE_SID}"
FORCE="${FORCE:-y}"        # y|n
FORMAT="${FORMAT:-12.2}"     # 12 recommended for 12c+
SYSBACKUP="${SYSBACKUP:-y}" # y|n (optional)
SYSKM="${SYSKM:-n}"        # y|n (optional)
SYSRAC="${SYSRAC:-n}"      # y|n (optional) - depends on env

log "Target ORACLE_SID=${ORACLE_SID}"
log "Target ORACLE_HOME=${ORACLE_HOME}"
log "Password file: ${PWDFILE}"

# ---- Backup existing password file (if present) ----
if [[ -f "$PWDFILE" ]]; then
  ts="$(date +%Y%m%d%H%M%S)"
  cp -p "$PWDFILE" "${PWDFILE}.bak.${ts}"
  log "Backed up existing password file to ${PWDFILE}.bak.${ts}"
fi

# ---- Create/replace password file ----
  log "generating orapwd passsword file" >&2
  # Prefer stdin prompt mode (keeps password out of process argv) when supported by orapwd.
  # Fall back to argv mode only if stdin prompt mode is unavailable in this binary/version.
  if ! printf '%s\n' "$ORACLE_PWD" | orapwd \
    file="$PWDFILE" \
    force="$FORCE" \
    format="$FORMAT" >/dev/null 2>&1; then
    log "orapwd stdin prompt mode not supported; using argv fallback."
    orapwd \
      file="$PWDFILE" \
      password="$ORACLE_PWD" \
      force="$FORCE" \
      format="$FORMAT"
  fi

chmod 600 "$PWDFILE"
log "Password file created/updated and permissions set to 600."

# ---- Reset SYS password in the database ----
xtrace_was_on=0
case "$-" in *x*) xtrace_was_on=1; set +x;; esac

# Quoting: password will still be sent to sqlplus, but not echoed by this block.
sqlplus -s / as sysdba <<SQL
set echo off verify off feedback off heading off pages 0
whenever sqlerror exit failure rollback
alter user sys identified by "$ORACLE_PWD";
-- optional: verify open mode / status if desired
exit
SQL

# ---- Clear sensitive variables from shell memory best-effort ----
if [[ $xtrace_was_on -eq 1 ]]; then set -x; fi

log "SYS password reset completed successfully."
fi
}

# Open the configured PDB after the CDB comes up.
# Skip cleanly when ORACLE_PDB is unset.
function openpdb() {
local is_cdb

is_cdb=$("$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<EOF
set heading off pagesize 0 feedback off verify off
SELECT cdb FROM v\$database;
EXIT;
EOF
)

if [[ "${is_cdb//[[:space:]]/}" == "YES" ]]; then
    if [[ -n "${ORACLE_PDB:-}" ]]; then
        echo "CDB detected. ORACLE_PDB is set to: $ORACLE_PDB"
    
        sqlplus / as sysdba <<EOF
ALTER PLUGGABLE DATABASE $ORACLE_PDB OPEN;
EXIT;
EOF
    else
        echo "CDB detected, but ORACLE_PDB variable is not set. Skipping PDB startup."
    fi
else
    echo "Non-CDB detected. Skipping PDB-specific operations."
fi
}

# Create the external OPS$oracle user used for local auth and health checks.
# Add PDB visibility grants when the database is a CDB.
function setosauthuser() {
   #Execute the SQL with the appropriate suffix
   sqlplus -s / as sysdba <<EOF
   ALTER SESSION SET "_oracle_script" = true;
   CREATE USER OPS\$oracle IDENTIFIED EXTERNALLY;
   GRANT CREATE SESSION TO OPS\$oracle;
   GRANT SELECT ON sys.v_\$database TO OPS\$oracle;


   DECLARE
     v_cdb VARCHAR2(3);
   BEGIN
     SELECT cdb INTO v_cdb FROM v\$database;

     IF v_cdb = 'YES' THEN
       EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ' || '$ORACLE_PDB' || ' SAVE STATE';
       EXECUTE IMMEDIATE 'GRANT SELECT ON sys.v_\$pdbs TO OPS\$oracle';
       EXECUTE IMMEDIATE 'ALTER USER OPS\$oracle SET container_data=all for sys.v_\$pdbs container = current';
     END IF;
   END;
   /
   exit;
EOF
}

# Ensure /etc/oratab contains an entry for the active SID and home.
# Append the entry when it does not already exist.
function setoratab() {
 ORATAB=/etc/oratab
## Check if SID exists in /etc/oratab
if grep -q "^${ORACLE_SID}:" $ORATAB; then
    # echo "Entry for $ORACLE_SID found in $ORATAB. Removing..."
    echo "Entry for $ORACLE_SID found in $ORATAB."
    # Remove the entry
    # sed -i.bak "/^${ORACLE_SID}:/d" $ORATAB
    # echo "Entry removed."
    # echo "Backup saved as ${ORATAB}.bak"
else
    echo "No entry found for $ORACLE_SID in $ORATAB"
    echo "$ORACLE_SID:$ORACLE_HOME:N" >> $ORATAB
    echo "ORACLE_HOME=$ORACLE_HOME"
fi
}

##############################
########### MAIN #############
##############################

#Madatory variables for oci_backup module to work and set the variables
JAVA_BIN="$ORACLE_HOME/jdk/bin/java"
RMAN_BIN="$ORACLE_HOME/bin/rman"
#####
if [[ -z $ORACLE_SID ]]; then
  echo "ORACLE_SID is not set. exiting"
  exit 1
fi

export NEW_ORACLE_SID=${ORACLE_SID}
if [[ -n "${SOURCE_DB_NAME:-}" ]]; then
  export ORACLE_SID=${SOURCE_DB_NAME}
fi

export OPC_WALLET_DIR="${OPC_WALLET_DIR:-$ORACLE_BASE/wallet}"
export OPC_LIB_DIR="${OPC_LIB_DIR:-$ORACLE_BASE/lib}"
export BACKUP_CONFIG_FILE="${BACKUP_CONFIG_FILE:-$ORACLE_BASE/oci/config/ocibackup.conf}"
export CONFIG_PARENT=$(dirname "${BACKUP_CONFIG_FILE}")
export OPC_LOG_DIR="${OPC_LOG_DIR:-/var/tmp}"
export FORCE_OPC_REINSTALL="${FORCE_OPC_REINSTALL:-false}"
export OPC_LOG_FILE="clonedb.log"
export SGA_TARGET="${INIT_SGA_SIZE:-4G}"
export PGA_AGGREGATE_TARGET="${INIT_PGA_SIZE:-2G}"
export DIAGNOSTIC_DEST="${ORACLE_BASE}"
export ORADATA_DIR="${ORACLE_BASE}/oradata/${NEW_ORACLE_SID}"
export LOG_DIR=$OPC_LOG_DIR
export PFILE_PATH="$OPC_LOG_DIR/init${ORACLE_SID}.ora"
export WALLET_ROOT=$ORADATA_DIR/wallets
export RESTORE_SOURCE_TYPE_EFFECTIVE="$(get_restore_source_type)"
export FS_BACKUP_PATH="${FS_BACKUP_PATH:-}"
export FS_BACKUP_CATALOG_START_WITH="${FS_BACKUP_CATALOG_START_WITH:-$FS_BACKUP_PATH}"
#####

if is_object_restore; then
  MANDATORY_PARAMS=(
      "OPC_HOST"
      "PVT_KEY_PATH"
      "FINGERPRINT"
      "USER_OCID"
      "TENANCY_OCID"
      "BUCKET_NAME"
      "DBID"
      "COMPARTMENT_OCID"
  )
else
  MANDATORY_PARAMS=(
      "DBID"
      "FS_BACKUP_PATH"
  )
fi

# Load allowed OCI connection keys from OCI_CONFIG_FILE into the environment.
# Reject malformed lines and unsupported keys before restore continues.
function load_oci_config_file() {
  # Optional allowlist. If you want "export everything", set ALLOWED_KEYS=() and remove the allowlist check below.
  local ALLOWED_KEYS=(
    OPC_HOST PVT_KEY_PATH FINGERPRINT USER_OCID TENANCY_OCID BUCKET_NAME DBID
  )

  [[ -n "${OCI_CONFIG_FILE:-}" ]] || return 0
  [[ -f "$OCI_CONFIG_FILE" ]] || { log "ERROR: OCI_CONFIG_FILE does not exist: $OCI_CONFIG_FILE"; exit 1; }

  while IFS= read -r line || [[ -n "$line" ]]; do
    # strip CR if file has CRLF
    line="${line%$'\r'}"

    # trim leading/trailing whitespace (Bash)
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # skip blanks/comments
    [[ -z "$line" || "$line" == \#* ]] && continue

    # must be KEY=VALUE with no spaces around '='
    if [[ ! "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]]; then
      log "ERROR: Invalid line in OCI_CONFIG_FILE ($OCI_CONFIG_FILE): $line"
      log "Expected KEY=VALUE"
      exit 1
    fi

    local key="${line%%=*}"
    local val="${line#*=}"

    # reject spaces around '=' (e.g., KEY =VAL, KEY= VAL, KEY = VAL)
    if [[ "$key" =~ [[:space:]] || "$val" =~ ^[[:space:]] ]]; then
      log "ERROR: Invalid spacing in OCI_CONFIG_FILE ($OCI_CONFIG_FILE): $line"
      log "Expected KEY=VALUE (no spaces around '=')"
      exit 1
    fi

    # allowlist (recommended)
    local allowed=false
    local k
    for k in "${ALLOWED_KEYS[@]}"; do
      if [[ "$key" == "$k" ]]; then
        allowed=true
        break
      fi
    done
    if [[ "$allowed" == false ]]; then
      log "ERROR: Unsupported key in OCI_CONFIG_FILE ($OCI_CONFIG_FILE): $key"
      exit 1
    fi

    # export safely
    export "$key=$val"
  done < "$OCI_CONFIG_FILE"
}

# Read a password file without trailing CR or LF characters.
# Exit with an error when the requested file is missing.
function read_password_from_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # Output the password without printing a newline or anything else.
    tr -d '\r\n' < "$file"
  else
    log "Error: File '$file' not found." >&2
    exit 1
  fi
}

if is_object_restore; then
  load_oci_config_file
fi

MISSING_VARS=()
for var in "${MANDATORY_PARAMS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    log "ERROR: The following required environment variables are not set:"
    for missing in "${MISSING_VARS[@]}"; do
        log "  - $missing"
    done
    exit 1
fi

# Step 4: Validate required runtime dependencies/paths

validate_runtime_tools

if is_object_restore; then
  if [ ! -f "$PVT_KEY_PATH" ]; then
      log "ERROR: Private key file not found at: $PVT_KEY_PATH"
      exit 1
  fi
else
  if [[ ! -d "${FS_BACKUP_PATH}" ]]; then
    log "ERROR: FS_BACKUP_PATH does not exist or is not a directory: ${FS_BACKUP_PATH}"
    exit 1
  fi
  if [[ ! -d "${FS_BACKUP_CATALOG_START_WITH}" ]]; then
    log "ERROR: FS_BACKUP_CATALOG_START_WITH does not exist or is not a directory: ${FS_BACKUP_CATALOG_START_WITH}"
    exit 1
  fi
fi

# Check if the SOURCE_DB_PWDFILE exists and read the password
if [[ ! -z "${SOURCE_DB_WALLET_PWDFILE:-}" ]]; then
if [[ -f "$SOURCE_DB_WALLET_PWDFILE" ]]; then
  # Set the SOURCE_DB_PWD variable from the file
  SOURCE_DB_WALLET_PWD=$(read_password_from_file "$SOURCE_DB_WALLET_PWDFILE")
else
  log "$SOURCE_DB_WALLET_PWDFILE does not exist." >&2
fi
fi

# Check if the DECRYPT_PWD_FILE exists and read the password
if [[ -n "${RMAN_DECRYPT_PWD_FILE:-}" ]]; then
if [[ -f "$RMAN_DECRYPT_PWD_FILE" ]]; then
  # Set the DECRYPT_PWD variable from the file
  DECRYPT_PWD=$(read_password_from_file "$RMAN_DECRYPT_PWD_FILE")
else
  log "Error: $RMAN_DECRYPT_PWD_FILE does not exist." >&2
  exit 1
fi
fi

# Optional FRA/SPFILE parameters for restored database.
# Supported envs (in precedence order):
#   DB_RECOVERY_FILE_DEST / DB_RECOVERY_FILE_DEST_SIZE
#   RECOVERY_AREA_LOCATION / RECOVERY_AREA_SIZE
#   RECOVERY_AREA_DESTINATION / RECOVERY_AREA_SIZE
DB_RECOVERY_DEST="${DB_RECOVERY_FILE_DEST:-${RECOVERY_AREA_LOCATION:-${RECOVERY_AREA_DESTINATION:-}}}"
DB_RECOVERY_DEST_SIZE="${DB_RECOVERY_FILE_DEST_SIZE:-${RECOVERY_AREA_SIZE:-}}"
if [[ -n "${DB_RECOVERY_DEST}" || -n "${DB_RECOVERY_DEST_SIZE}" ]]; then
  if [[ -z "${DB_RECOVERY_DEST}" || -z "${DB_RECOVERY_DEST_SIZE}" ]]; then
    log "ERROR: Recovery area configuration requires both destination and size. Set DB_RECOVERY_FILE_DEST and DB_RECOVERY_FILE_DEST_SIZE (or RECOVERY_AREA_LOCATION/RECOVERY_AREA_SIZE)."
    exit 1
  fi
  if [[ ! -d "${DB_RECOVERY_DEST}" ]]; then
    log "ERROR: Recovery area destination does not exist: ${DB_RECOVERY_DEST}."
    exit 1
  fi
fi

####Calling functions#####
create_dirs
install_opc
unzipwallet
generatepfile
startupdb "pfile"
openwallet
rmanrestorespfile
###### Modify Spfile and recrete it###
spfile="$ORACLE_HOME/dbs/spfile${ORACLE_SID}.ora"
pfile="$ORACLE_HOME/dbs/init${ORACLE_SID}.ora"
delete_list=(
   open_cursors
   use_large_pages
   cluster_database
   sga_max_size
   sga_target
   pga_aggregate_limit
   pga_aggregate_target
   remote_listener
   local_listener
   cluster_database_instances
   db_create_online_log_dest_1
   wallet_root
   audit_file_dest
   db_recovery_file_dest
   db_recovery_file_dest_size
   log_archive_dest_[0-9]+
   '[^.]+\.cluster_interconnects'
   '^[^.]+\.__.*' )

param_list=(
  "control_files='${ORADATA_DIR}/CONTROLFILE/control.ctl'"
  "db_create_file_dest='${ORADATA_DIR}'"
  "db_create_online_log_dest_1='${ORADATA_DIR}'"
  "sga_target=${SGA_TARGET}"
  "PGA_AGGREGATE_TARGET=${PGA_AGGREGATE_TARGET}"
  "wallet_root='${WALLET_ROOT}'"
  "diagnostic_dest='${DIAGNOSTIC_DEST}'"
  )

if [[ -n "${DB_RECOVERY_DEST}" && -n "${DB_RECOVERY_DEST_SIZE}" ]]; then
  param_list+=(
    "db_recovery_file_dest='${DB_RECOVERY_DEST}'"
    "db_recovery_file_dest_size=${DB_RECOVERY_DEST_SIZE}"
  )
else
  param_list+=(
    "db_recovery_file_dest='${ORADATA_DIR}'"
    "db_recovery_file_dest_size=50G"
  )
fi

# Detect if it's a RAC setup or SID setup and call the function
modifyspfile "$spfile" "$pfile" --delete "${delete_list[@]}" --set "${param_list[@]}"
startupdb "spfile"
openwallet
#openpdbwallet
rmanvalidatecontrolfileautobackup
rmanrestorecontrolfile
rmancrosscheckbackup
rmanvalidatedatabase
rmanrestoredb
openpdbwallet
openpdb
dropTempFiles
changedbname
recreateTempTbs
#openpdb
createstartlistener
settnsames
setoratab
setosauthuser
