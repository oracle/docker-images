#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
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

   mv "$ORACLE_HOME"/dbs/spfile"$ORACLE_SID".ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/dbs/orapw"$ORACLE_SID" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/sqlnet.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/listener.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/tnsnames.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/install/.docker_* "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/

   # oracle user does not have permissions in /etc, hence cp and not mv
   cp /etc/oratab "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   
   symLinkFiles;
}

########### Symbolic link DB files ############
function symLinkFiles {

   if [ ! -L "$ORACLE_HOME"/dbs/spfile"$ORACLE_SID".ora ]; then
      ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/spfile"$ORACLE_SID".ora "$ORACLE_HOME"/dbs/spfile"$ORACLE_SID".ora
   fi;
   
   if [ ! -L "$ORACLE_HOME"/dbs/orapw"$ORACLE_SID" ]; then
      ln -s "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/orapw"$ORACLE_SID" "$ORACLE_HOME"/dbs/orapw"$ORACLE_SID"
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

   # oracle user does not have permissions in /etc, hence cp and not ln 
   cp "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/oratab /etc/oratab

}

########### Undoing the symbolic links ############
function undoSymLinkFiles {

   if [ -L "$ORACLE_HOME"/dbs/spfile"$ORACLE_SID".ora ]; then
      rm "$ORACLE_HOME"/dbs/spfile"$ORACLE_SID".ora
   fi;

   if [ -L "$ORACLE_HOME"/dbs/orapw"$ORACLE_SID" ]; then
      rm "$ORACLE_HOME"/dbs/orapw"$ORACLE_SID"
   fi;

   if [ -L "$ORACLE_HOME"/network/admin/sqlnet.ora ]; then
      rm "$ORACLE_HOME"/network/admin/sqlnet.ora
   fi;

   if [ -L "$ORACLE_HOME"/network/admin/listener.ora ]; then
      rm "$ORACLE_HOME"/network/admin/listener.ora
   fi;

   if [ -L "$ORACLE_HOME"/network/admin/tnsnames.ora ]; then
      rm "$ORACLE_HOME"/network/admin/tnsnames.ora
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

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Only EE is supported for 19c on ARM64 platform
if [ "$(arch)" == "aarch64" ] || [ "$(arch)" == "arm64" ]; then
  if { [ "${ORACLE_EDITION^^}" != "" ] && [ "${ORACLE_EDITION^^}" != "ENTERPRISE" ]; }; then
    echo "${ORACLE_EDITION} edition is not supported on ARM64 platform.";
    exit 1;
  fi;
fi;

# Check whether container has enough memory
if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
   memory=$(cat /sys/fs/cgroup/memory.max)
else
   memory=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
fi

# Default memory to 2GB, if not able to fetch memory restrictions from cgroups
export ALLOCATED_MEMORY=$((${memory:=2147483648}/1024/1024))

# Github issue #219: Prevent integer overflow,
# only check if memory digits are less than 11 (single GB range and below)
if [[ ${memory} != "max" && ${#memory} -lt 11 && ${memory} -lt 2147483648 ]]; then
   echo "Error: The container doesn't have enough memory allocated."
   echo "A database container needs at least 2 GB of memory."
   echo "You currently only have $ALLOCATED_MEMORY MB allocated to the container."
   exit 1;
fi

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

# Shared TDE secret helper functions
TDE_SECRET_UTILS_FILE="${TDE_SECRET_UTILS_FILE:-tdeSecretUtils.sh}"
if [ -f "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE" ]; then
   # shellcheck source=/dev/null
   . "${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE"
else
   echo "ERROR: Missing required TDE helper: ${SCRIPT_BASE_DIR}/$TDE_SECRET_UTILS_FILE. Exiting..."
   exit 1
fi

# Setting up ORACLE_PWD if secret file is present.
# Defaults keep existing behavior: /run/secrets/oracle_pwd
SECRET_VOLUME="${SECRET_VOLUME:-/run/secrets}"
ORACLE_PWD_SECRET_NAME="${PASSWORD_FILE:-${ORACLE_PWD_SECRET_NAME:-oracle_pwd}}"
ORACLE_PWD_SECRET_FILE="${SECRET_VOLUME}/${ORACLE_PWD_SECRET_NAME}"
if [ -e "${ORACLE_PWD_SECRET_FILE}" ]; then
   ORACLE_PWD="$(cat "${ORACLE_PWD_SECRET_FILE}")"
   export ORACLE_PWD
fi

# Optional TDE password secret setup for DBCA.
TDE_ENABLED="${TDE_ENABLED:-false}"
if [ "${TDE_ENABLED}" = "true" ] && [ "${STANDBY_DB}" != "true" ]; then
   if ! tde_require_primary_password; then
      exit 1
   fi
fi
export TDE_ENABLED ORACLE_TDE_PWD_SECRET_NAME ORACLE_TDE_SECRET_FILE SECRET_VOLUME

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

# Default for ORACLE PDB
export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}

# Make ORACLE_PDB upper case
# Github issue # 984
export ORACLE_PDB=${ORACLE_PDB^^}

# Default for ORACLE CHARACTERSET
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}
ENABLE_DEBUG="${ENABLE_DEBUG:-false}"
export ENABLE_DEBUG

# Call relinkOracleBinary.sh before the database is created or started.
# Prefer the canonical script-base path; the ORACLE_BASE path is a compatibility
# wrapper and is safe to execute, but not to source.
RELINK_SCRIPT_PATH="${SCRIPT_BASE_DIR}/${RELINK_BINARY_FILE}"
if [ ! -f "${RELINK_SCRIPT_PATH}" ]; then
   RELINK_SCRIPT_PATH="${ORACLE_BASE}/${RELINK_BINARY_FILE}"
fi
# shellcheck disable=SC1090
. "${RELINK_SCRIPT_PATH}"

# Check whether database already exists
if [ -f "$ORACLE_BASE"/oradata/."${ORACLE_SID}""${CHECKPOINT_FILE_EXTN}" ] && [ -d "$ORACLE_BASE"/oradata/"${ORACLE_SID}" ]; then
   symLinkFiles;
   
   # Make sure audit file destination exists
   if [ ! -d "$ORACLE_BASE"/admin/"$ORACLE_SID"/adump ]; then
      mkdir -p "$ORACLE_BASE"/admin/"$ORACLE_SID"/adump
   fi;
   
   # Start database
   "${SCRIPT_BASE_DIR}"/"$START_FILE";

   # In case of the prebuiltdb extended image container, provision changing password by ORACLE_PWD
   if [ -n "${ORACLE_PWD}" ] && [ -e "${ORACLE_BASE}/oradata/${ORACLE_SID}/.prebuiltdb" ]; then
      "${SCRIPT_BASE_DIR}"/"${PWD_FILE}" "${ORACLE_PWD}"
   fi
   
else
  undoSymLinkFiles;

  # Remove database config files, if they exist
  rm -f "$ORACLE_HOME"/dbs/spfile"$ORACLE_SID".ora
  rm -f "$ORACLE_HOME"/dbs/orapw"$ORACLE_SID"
  rm -f "$ORACLE_HOME"/network/admin/sqlnet.ora
  rm -f "$ORACLE_HOME"/network/admin/listener.ora
  rm -f "$ORACLE_HOME"/network/admin/tnsnames.ora

  # Clean up incomplete database
  rm -rf "$ORACLE_BASE"/oradata/"$ORACLE_SID"
  cp /etc/oratab oratab.bkp
  sed "/^#/!d" oratab.bkp > /etc/oratab
  rm -f oratab.bkp
  rm -rf "$ORACLE_BASE"/cfgtoollogs/dbca/"$ORACLE_SID"
  rm -rf "$ORACLE_BASE"/admin/"$ORACLE_SID"

  # clean up zombie shared memory/semaphores
  ipcs -m | awk ' /[0-9]/ {print $2}' | xargs -n1 ipcrm -m 2> /dev/null
  ipcs -s | awk ' /[0-9]/ {print $2}' | xargs -n1 ipcrm -s 2> /dev/null

  # Create database and checking option as if you use backup then DBCA will not be involved
  if [[ -n "${CLONE_DB_FROM_OBJ_BACKUP:-}" || -n "${CLONE_DB_FROM_FS_BACKUP:-}" ]]; then
      run_or_debug "cloneDBObjBkup.sh" "${SCRIPT_BASE_DIR}"/"$CLONEDB_OBJBACKUP" || exit 1
  else
   run_or_debug "createDB.sh" "${SCRIPT_BASE_DIR}"/"$CREATE_DB_FILE" "$ORACLE_SID" "$ORACLE_PDB" "$ORACLE_PWD" || exit 1;
  fi 

  # Check whether database is successfully created
  if "${SCRIPT_BASE_DIR}"/"$CHECK_DB_FILE"; then
    # Create a checkpoint file if database is successfully created
    # Populate the checkpoint file with the current date to avoid timing issue when using NFS persistence in multi-replica mode
    date -Iseconds > "$ORACLE_BASE"/oradata/."${ORACLE_SID}""${CHECKPOINT_FILE_EXTN}"
  fi

  # Move database operational files to oradata
  moveFiles;

  # Execute setup script for extensions
  "${SCRIPT_BASE_DIR}"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/extensions/setup

  # Execute custom provided setup scripts
  "${SCRIPT_BASE_DIR}"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/setup

   # Setup TCPS with the database
  if [[ -n "${ENABLE_TCPS}" && "${ENABLE_TCPS}" = "true" ]]; then
    run_or_debug "configTcps.sh" "${SCRIPT_BASE_DIR}"/"${CONFIG_TCPS_FILE}" || exit 1
  fi

fi;

# Check whether database is up and running
"${SCRIPT_BASE_DIR}"/"$CHECK_DB_FILE"
status=$?

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
