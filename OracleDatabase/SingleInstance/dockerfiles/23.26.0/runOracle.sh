#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Runs the Oracle Database inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

########### Move DB files ############
function moveFiles {

   if [ ! -d "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID" ]; then
      mkdir -p "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   fi;

   if [ -d "$ORACLE_BASE_CONFIG"/dbs ]; then
      if [ -d "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/dbs ]; then
         cp -a "$ORACLE_BASE_CONFIG"/dbs/. "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/dbs/
         rm -rf "$ORACLE_BASE_CONFIG"/dbs
      else
         mv "$ORACLE_BASE_CONFIG"/dbs "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
      fi
   fi
   mv "$ORACLE_HOME"/network/admin/sqlnet.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/listener.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/tnsnames.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/

   if [ "${CONFIGURE_TDE}" = "true" ]; then  
      mv $ORACLE_BASE/admin/$ORACLE_SID/wallet_root/tde "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   fi;

   if [ -a "$ORACLE_HOME"/install/.docker_* ]; then
      mv "$ORACLE_HOME"/install/.docker_* "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   fi;

   # oracle user does not have permissions in /etc, hence cp and not mv
   cp /etc/oratab "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   
   symLinkFiles;
}

########### Symbolic link DB files ############
function symLinkFiles {

   if [ ! -L "$ORACLE_BASE_CONFIG"/dbs ]; then
      rm -rf "$ORACLE_BASE_CONFIG"/dbs && ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/dbs "$ORACLE_BASE_CONFIG"
   fi;
   
   if [ ! -L "$ORACLE_HOME"/network/admin/sqlnet.ora ]; then
      ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/sqlnet.ora "$ORACLE_HOME"/network/admin/sqlnet.ora
   fi;

   if [ ! -L "$ORACLE_HOME"/network/admin/listener.ora ]; then
      ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora "$ORACLE_HOME"/network/admin/listener.ora
   fi;

   if [ ! -L "$ORACLE_HOME"/network/admin/tnsnames.ora ]; then
      ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/tnsnames.ora "$ORACLE_HOME"/network/admin/tnsnames.ora
   fi;

   if [ "${CONFIGURE_TDE}" = "true" ] && [ ! -L "$ORACLE_BASE"/admin/"$ORACLE_SID"/wallet_root/tde ]; then
      rm -rf "$ORACLE_BASE"/admin/"$ORACLE_SID"/wallet_root/tde 
      if [ ! -d "$ORACLE_BASE"/admin/"$ORACLE_SID"/wallet_root ]; then
         mkdir -p "$ORACLE_BASE"/admin/"$ORACLE_SID"/wallet_root
      fi;
      ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/tde "$ORACLE_BASE"/admin/"$ORACLE_SID"/wallet_root
   fi;

   # oracle user does not have permissions in /etc, hence cp and not ln 
   cp "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/oratab /etc/oratab

}

########### Undoing the symbolic links ############
function undoSymLinkFiles {

   if [ -L $ORACLE_BASE_CONFIG/dbs ]; then
      rm $ORACLE_BASE_CONFIG/dbs && mkdir $ORACLE_BASE_CONFIG/dbs
   fi;

   if [ -L $ORACLE_HOME/network/admin/sqlnet.ora ]; then
      rm $ORACLE_HOME/network/admin/sqlnet.ora
   fi;

   if [ -L $ORACLE_HOME/network/admin/listener.ora ]; then
      rm $ORACLE_HOME/network/admin/listener.ora
   fi;

   if [ -L $ORACLE_HOME/network/admin/tnsnames.ora ]; then
      rm $ORACLE_HOME/network/admin/tnsnames.ora
   fi;

   if [ "${CONFIGURE_TDE}" = "true" ] && [ -L $ORACLE_BASE/admin/$ORACLE_SID/wallet_root/tde ]; then
      rm $ORACLE_BASE/admin/$ORACLE_SID/wallet_root/tde
   fi;
   
}

SCRIPT_BASE_DIR="${SCRIPT_BASE_DIR:-/opt/oracle/scripts/base}"
SHUTDOWN_FILE="${SHUTDOWN_FILE:-shutDown.sh}"

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down database!"
   "${SCRIPT_BASE_DIR}/${SHUTDOWN_FILE}" immediate
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down database!"
   "${SCRIPT_BASE_DIR}/${SHUTDOWN_FILE}" immediate
}

########### Debug hold helper ############
function debug_hold_on_error() {
   local step_name="$1"
   local exit_code="$2"
   echo "#####################################"
   echo "########### E R R O R ###############"
   echo "Step failed: ${step_name}"
   echo "Exit code : ${exit_code}"
   echo "ENABLE_DEBUG=true, keeping container alive for debugging."
   echo "Useful logs:"
   echo "  - DBCA logs: ${ORACLE_BASE}/cfgtoollogs/dbca"
   echo "  - Alert logs: ${ORACLE_BASE}/diag/rdbms/*/*/trace/alert*.log"
   echo "########### E R R O R ###############"
   echo "#####################################"
   tail -f /dev/null
}

########### Run command with optional debug hold ############
function run_or_debug() {
   local step_name="$1"
   shift

   "$@"
   local rc=$?
   if [ $rc -ne 0 ]; then
      if [ "${ENABLE_DEBUG}" = "true" ]; then
         debug_hold_on_error "${step_name}" "$rc"
      fi
      return $rc
   fi
   return 0
}

########### Move true cache into read-only apply mode ############
function nudge_true_cache_to_ready_state() {
   local db_state=""
   local rc=0

   if [ "${TRUE_CACHE}" != "true" ]; then
      return 0
   fi

   db_state=$(sqlplus -s / as sysdba <<EOF
set heading off
set feedback off
set pagesize 0
set verify off
SELECT database_role || '|' || open_mode FROM v\$database;
exit;
EOF
)
   rc=$?
   if [ $rc -ne 0 ]; then
      echo "Unable to inspect true cache state yet; sqlplus exited with ${rc}."
      return $rc
   fi

   DB_ROLE=$(echo "$db_state" | cut -d'|' -f1 | xargs)
   DB_OPEN_MODE=$(echo "$db_state" | cut -d'|' -f2- | xargs)

   if [ "$DB_ROLE" != "TRUE CACHE" ]; then
      return 0
   fi

   echo "True cache state detected: role=${DB_ROLE}, open_mode=${DB_OPEN_MODE}"

   sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON
DECLARE
   l_open_mode VARCHAR2(64);
BEGIN
   SELECT open_mode INTO l_open_mode FROM v\$database;

   IF l_open_mode = 'MOUNTED' THEN
      DBMS_OUTPUT.PUT_LINE('Opening true cache database read only.');
      EXECUTE IMMEDIATE 'ALTER DATABASE OPEN READ ONLY';
      SELECT open_mode INTO l_open_mode FROM v\$database;
   END IF;

   IF l_open_mode IN ('READ ONLY', 'READ ONLY WITH APPLY') THEN
      FOR pdb IN (
         SELECT name
           FROM v\$pdbs
          WHERE name <> 'PDB\$SEED'
            AND open_mode <> 'READ ONLY'
      ) LOOP
         DBMS_OUTPUT.PUT_LINE('Opening PDB ' || pdb.name || ' READ ONLY.');
         EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE "' || REPLACE(pdb.name, '"', '""') || '" OPEN READ ONLY';
      END LOOP;
   END IF;

   IF l_open_mode = 'READ ONLY' THEN
      DBMS_OUTPUT.PUT_LINE('Starting managed recovery for true cache.');
      EXECUTE IMMEDIATE 'ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION';
   END IF;
END;
/
EXIT;
EOF
   rc=$?
   if [ $rc -ne 0 ]; then
      echo "Unable to advance true cache to READ ONLY WITH APPLY yet; sqlplus exited with ${rc}."
   fi
   return $rc
}

########### Wait for database readiness with bounded timeout ############
function wait_for_database_ready() {
   local elapsed=0
   local status=1
   local sleep_for=0
   local idx=0
   local last_idx=0
   local -a backoffs=()

   read -r -a backoffs <<< "$DB_STATUS_CHECK_BACKOFFS"
   if [ ${#backoffs[@]} -eq 0 ]; then
      backoffs=(1 2 4 8 16 32 64)
   fi
   last_idx=$((${#backoffs[@]} - 1))

   while true; do
      "$ORACLE_BASE"/"$CHECK_DB_FILE"
      status=$?

      if [ "${TRUE_CACHE}" = "true" ] && { [ $status -eq 5 ] || [ $status -eq 2 ]; }; then
         nudge_true_cache_to_ready_state || true
         "$ORACLE_BASE"/"$CHECK_DB_FILE"
         status=$?
      fi

      if [ $status -ne 5 ] && ! { [ "${TRUE_CACHE}" = "true" ] && [ $status -eq 2 ]; }; then
         return $status
      fi

      if [ $elapsed -ge "$DB_READY_TIMEOUT_SECONDS" ]; then
         echo "Timed out after ${DB_READY_TIMEOUT_SECONDS} seconds waiting for the database to become ready."
         return $status
      fi

      sleep_for=${backoffs[$idx]}
      if [ $idx -lt $last_idx ]; then
         idx=$((idx + 1))
      fi

      if [ $((elapsed + sleep_for)) -gt "$DB_READY_TIMEOUT_SECONDS" ]; then
         sleep_for=$((DB_READY_TIMEOUT_SECONDS - elapsed))
      fi

      if [ $sleep_for -le 0 ]; then
         echo "Timed out after ${DB_READY_TIMEOUT_SECONDS} seconds waiting for the database to become ready."
         return $status
      fi

      echo "Database is not ready yet. Waiting for $sleep_for seconds."
      sleep "$sleep_for"
      elapsed=$((elapsed + sleep_for))
   done
}

if [ "${RUNORACLE_UNIT_TEST_MODE:-false}" = "true" ]; then
   return 0 2>/dev/null || exit 0
fi

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Check whether container has enough memory
if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
  memory=$(cat /sys/fs/cgroup/memory.max)
else
  memory=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
fi

export ALLOCATED_MEMORY=$((${memory:=2147483648}/1024/1024))

# Github issue #219: Prevent integer overflow,
# only check if memory digits are less than 11 (single GB range and below) 
if [[ ${memory} != "max" && ${#memory} -lt 11 && ${memory} -lt 2147483648 ]]; then
    echo "Error: The container doesn't have enough memory allocated."
    echo "A database container needs at least 2 GB of memory."
    echo "You currently only have $ALLOCATED_MEMORY MB allocated to the container."
    exit 1;
fi;

# Check that hostname doesn't container any "_"
# Github issue #711
if hostname | grep -q "_"; then
   echo "Error: The hostname must not container any '_'".
   echo "Your current hostname is '$(hostname)'"
fi;

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

TDE_SECRET_UTILS_FILE="${TDE_SECRET_UTILS_FILE:-tdeSecretUtils.sh}"
if [ -f "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE" ]; then
   # shellcheck source=/dev/null
   . "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE"
else
   echo "ERROR: Missing required TDE helper: ${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE. Exiting..."
   exit 1
fi

# Default for ORACLE SID
if [ "$ORACLE_SID" == "" ]; then
   export ORACLE_SID=ORCLCDB
else
  # Make ORACLE_SID upper case
  # Github issue # 984
  export ORACLE_SID=${ORACLE_SID^^}

  # Check whether SID is no longer than 12 bytes
  # Github issue #246: Cannot start OracleDB image
  if [ "${#ORACLE_SID}" -gt 12 ]; then
     echo "Error: The ORACLE_SID must only be up to 12 characters long."
     exit 1;
  fi;

  # Check whether SID is alphanumeric
  # Github issue #246: Cannot start OracleDB image
  if [[ "$ORACLE_SID" =~ [^a-zA-Z0-9] ]]; then
     echo "Error: The ORACLE_SID must be alphanumeric."
     exit 1;
   fi;
fi;

export ORACLE_PWD=$("${SCRIPT_BASE_DIR}/$DECRYPT_PWD_FILE")

# Optional TDE password secret setup for DBCA.
SECRET_VOLUME="${SECRET_VOLUME:-/run/secrets}"
TDE_ENABLED="${TDE_ENABLED:-false}"
if [ "${TDE_ENABLED}" = "true" ] && [ "${STANDBY_DB}" != "true" ]; then
   if ! tde_require_primary_password; then
      exit 1
   fi
fi
export TDE_ENABLED ORACLE_TDE_PWD_SECRET_NAME ORACLE_TDE_SECRET_FILE SECRET_VOLUME

# Sanitizing env for FREE
if [ "${ORACLE_SID}" = "FREE" ]; then
   export ORACLE_PDB="FREEPDB1"
   unset DG_OBSERVER_ONLY CLONE_DB STANDBY_DB
fi

# Creation of Observer only section
if [ "${DG_OBSERVER_ONLY}" = "true" ]; then
   if [ -z "${DG_OBSERVER_NAME}" ]; then
      # Auto generate the observer name if not given
      DG_OBSERVER_NAME="observer-$(openssl rand -hex 4)"
      export DB_OBSERVER_NAME
   fi 
   export DG_OBSERVER_DIR=${ORACLE_BASE}/oradata/${DG_OBSERVER_NAME}

   # Calling the script to create observer
   "${SCRIPT_BASE_DIR}"/"$CREATE_OBSERVER_FILE" "$DG_OBSERVER_NAME" "$PRIMARY_DB_CONN_STR" "${ORACLE_PWD:?'ORACLE_PWD not set. Exiting...'}" "$DG_OBSERVER_DIR"

   if [ ! -f "$DG_OBSERVER_DIR/observer.log" ]; then
      # Display the content of nohup.out to show errors
      if [ -f "$DG_OBSERVER_DIR/nohup.out" ]; then
         cat "$DG_OBSERVER_DIR"/nohup.out
         echo "Observer is not able to start. Exiting..."
      else
         echo "Observer creation and startup fail !! Exiting..."
      fi
      exit 1
   else
      # Tail on observer log and wait (otherwise container will exit)
      echo "The following output is now a tail of the observer.log:"
      tail -f "$DG_OBSERVER_DIR"/observer.log &
      childPID=$!
      wait $childPID

      # Show nohup output and exit
      echo "Exiting..."
      cat "$DG_OBSERVER_DIR"/nohup.out
      exit 0;
   fi
fi

# Read-only Oracle Home Config
ORACLE_BASE_CONFIG=$("$ORACLE_HOME"/bin/orabaseconfig)
export ORACLE_BASE_CONFIG

# Default for ORACLE PDB
export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}

# Make ORACLE_PDB upper case
# Github issue # 984
export ORACLE_PDB=${ORACLE_PDB^^}

# Default for ORACLE CHARACTERSET
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}
ENABLE_DEBUG="${ENABLE_DEBUG:-false}"
export ENABLE_DEBUG
DB_STATUS_CHECK_BACKOFFS="${DB_STATUS_CHECK_BACKOFFS:-1 2 4 8 16 32 64}"
export DB_STATUS_CHECK_BACKOFFS
DB_READY_TIMEOUT_SECONDS="${DB_READY_TIMEOUT_SECONDS:-600}"
export DB_READY_TIMEOUT_SECONDS

# Call relinkOracleBinary.sh before the database is created or started.
# Prefer the canonical script-base path and keep ORACLE_BASE as a fallback for
# compatibility with older image layouts.
if [ "${ORACLE_SID}" != "FREE" ]; then
   RELINK_SCRIPT_PATH="${SCRIPT_BASE_DIR}/${RELINK_BINARY_FILE}"
   if [ ! -f "${RELINK_SCRIPT_PATH}" ]; then
      RELINK_SCRIPT_PATH="${ORACLE_BASE}/${RELINK_BINARY_FILE}"
   fi
   source "${RELINK_SCRIPT_PATH}"
fi;

# In case of True Cache, remove checkpoint file so that new True Cache is created instead of reusing prebuilt db
if [ "$TRUE_CACHE" = "true" ] && [ -e "${ORACLE_BASE}/oradata/${ORACLE_SID}/.prebuiltdb" ]; then
   rm -rf "$ORACLE_BASE"/oradata/.${ORACLE_SID}"${CHECKPOINT_FILE_EXTN}" "${ORACLE_BASE}/oradata/${ORACLE_SID}/.prebuiltdb";
fi

# Check whether database already exists
if [ -f "$ORACLE_BASE"/oradata/.${ORACLE_SID}"${CHECKPOINT_FILE_EXTN}" ] && [ -d "$ORACLE_BASE"/oradata/"${ORACLE_SID}" ]; then
   symLinkFiles;
   
   # Make sure audit file destination exists
   if [ ! -d "$ORACLE_BASE"/admin/$ORACLE_SID/adump ]; then
      mkdir -p "$ORACLE_BASE"/admin/$ORACLE_SID/adump
   fi;
   
   # Start database
   if [ "${ORACLE_SID}" = "FREE" ]; then
      /etc/init.d/oracle-free-26ai start
   else
      "${SCRIPT_BASE_DIR}"/"$START_FILE";
   fi

   # In case of the prebuiltdb extended image container, provision changing password by ORACLE_PWD
   if [ -n "${ORACLE_PWD}" ] && [ -e "${ORACLE_BASE}/oradata/${ORACLE_SID}/.prebuiltdb" ]; then
      "${SCRIPT_BASE_DIR}"/"${PWD_FILE}" "${ORACLE_PWD}"
   fi
   
else
  undoSymLinkFiles;

  # Remove database config files, if they exist
  rm -f "$ORACLE_BASE_CONFIG"/dbs/spfile$ORACLE_SID.ora
  rm -f "$ORACLE_BASE_CONFIG"/dbs/orapw$ORACLE_SID
  rm -f "$ORACLE_HOME"/network/admin/sqlnet.ora
  rm -f "$ORACLE_HOME"/network/admin/listener.ora
  rm -f "$ORACLE_HOME"/network/admin/tnsnames.ora

  # Clean up incomplete database
  rm -rf "$ORACLE_BASE"/oradata/$ORACLE_SID
  cp /etc/oratab oratab.bkp
  sed "/^#/!d" oratab.bkp > /etc/oratab
  rm -f oratab.bkp
  rm -rf "$ORACLE_BASE"/cfgtoollogs/dbca/$ORACLE_SID
  rm -rf "$ORACLE_BASE"/admin/$ORACLE_SID

  # clean up zombie shared memory/semaphores
  ipcs -m | awk ' /[0-9]/ {print $2}' | xargs -n1 ipcrm -m 2> /dev/null
  ipcs -s | awk ' /[0-9]/ {print $2}' | xargs -n1 ipcrm -s 2> /dev/null

  # Create database and chcking option as if you use backup then DBCA will not be involved
  if [[ -n "${CLONE_DB_FROM_OBJ_BACKUP:-}" || -n "${CLONE_DB_FROM_FS_BACKUP:-}" ]]; then 
      run_or_debug "cloneDBObjBkup.sh" "${SCRIPT_BASE_DIR}"/"$CLONEDB_OBJBACKUP" || exit 1
  else
   run_or_debug "createDB.sh" "${SCRIPT_BASE_DIR}"/"$CREATE_DB_FILE" "$ORACLE_SID" "$ORACLE_PDB" "$ORACLE_PWD" || exit 1;
  fi 

   wait_for_database_ready
   ret=$?
   # Check whether database is successfully created
   if [ $ret -eq 0 ]; then
      # Create a checkpoint file if database is successfully created
      # Populate the checkpoint file with the current date to avoid timing issue when using NFS persistence in multi-replica mode
      echo "$(date -Iseconds)" > "$ORACLE_BASE"/oradata/.${ORACLE_SID}"${CHECKPOINT_FILE_EXTN}"
   fi
  
  # Move database operational files to oradata
  moveFiles;

  # Execute setup script for extensions
  "${SCRIPT_BASE_DIR}"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/extensions/setup
  
  # Execute custom provided setup scripts
  "${SCRIPT_BASE_DIR}"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/setup

  # Setup TCPS with the database
  if [ "${ENABLE_TCPS}" = "true" ]; then
    run_or_debug "configTcps.sh" "${SCRIPT_BASE_DIR}"/"${CONFIG_TCPS_FILE}" || exit 1
  fi

fi;

wait_for_database_ready
status=$?

# Check whether database is up and running
if [ $status -eq 0 ]; then
  echo "#########################"
  echo "DATABASE IS READY TO USE!"
  echo "#########################"

  # Execute startup script for extensions
  "${SCRIPT_BASE_DIR}"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/extensions/startup

  # Execute custom provided startup scripts
  "${SCRIPT_BASE_DIR}"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/startup
  
else
  echo "#####################################"
  echo "########### E R R O R ###############"
  echo "DATABASE SETUP WAS NOT SUCCESSFUL!"
  echo "Please check output for further info!"
  echo "########### E R R O R ###############" 
  echo "#####################################"
fi;

# Exiting the script without waiting on the tail logs
if [ "$1" = "--nowait" ]; then
   # Creating state-file for identifyig container of the prebuiltdb extended image
   touch "${ORACLE_BASE}/oradata/${ORACLE_SID}/.prebuiltdb"
   exit $status;
fi

# Tail on alert log and wait (otherwise container will exit)
echo "The following output is now a tail of the alert.log:"
tail -f "$ORACLE_BASE"/diag/rdbms/*/*/trace/alert*.log &
childPID=$!
wait $childPID
