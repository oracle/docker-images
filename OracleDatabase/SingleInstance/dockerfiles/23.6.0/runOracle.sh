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

   mv "$ORACLE_BASE_CONFIG"/dbs "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/sqlnet.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/listener.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   mv "$ORACLE_HOME"/network/admin/tnsnames.ora "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/
   find "$ORACLE_HOME"/install/ -name ".docker_*"  -exec  mv {} "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/  \;

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

}

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

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

ORACLE_PWD=$($ORACLE_BASE/$DECRYPT_PWD_FILE)
export ORACLE_PWD

# Setting up TDE_WALLET_PWD if podman secret is passed on
if [ -e '/run/secrets/tde_wallet_pwd' ]; then
   TDE_WALLET_PWD="$(cat '/run/secrets/tde_wallet_pwd')"
   export TDE_WALLET_PWD
fi

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
   "$ORACLE_BASE"/"$CREATE_OBSERVER_FILE" "$DG_OBSERVER_NAME" "$PRIMARY_DB_CONN_STR" "${ORACLE_PWD:?'ORACLE_PWD not set. Exiting...'}" "$DG_OBSERVER_DIR"

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

# Call relinkOracleBinary.sh before the database is created or started
if [ "${ORACLE_SID}" != "FREE" ]; then
   # shellcheck source=/dev/null
   source "$ORACLE_BASE/$RELINK_BINARY_FILE"
fi;

# Check whether database already exists
if [ -f "$ORACLE_BASE"/oradata/.${ORACLE_SID}"${CHECKPOINT_FILE_EXTN}" ] && [ -d "$ORACLE_BASE"/oradata/"${ORACLE_SID}" ]; then
   symLinkFiles;
   
   # Make sure audit file destination exists
   if [ ! -d "$ORACLE_BASE"/admin/$ORACLE_SID/adump ]; then
      mkdir -p "$ORACLE_BASE"/admin/$ORACLE_SID/adump
   fi;
   
   # Start database
   if [ "${ORACLE_SID}" = "FREE" ]; then
      su -c '/etc/init.d/oracle-free-23ai start'
   else
      "$ORACLE_BASE"/"$START_FILE";
   fi

   # In case of the prebuiltdb extended image container, provision changing password by ORACLE_PWD
   if [ -n "${ORACLE_PWD}" ] && [ -e "${ORACLE_BASE}/oradata/${ORACLE_SID}/.prebuiltdb" ]; then
      "${ORACLE_BASE}"/"${PWD_FILE}" "${ORACLE_PWD}"
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

  # Create database
  "$ORACLE_BASE"/"$CREATE_DB_FILE" $ORACLE_SID "$ORACLE_PDB" "$ORACLE_PWD" || exit 1;

   for i in 1 2 4 8; do
      IGNORE_DB_STARTED_MARKER=true "$ORACLE_BASE"/"$CHECK_DB_FILE";
      ret=$?
      # Check whether database is successfully created
      if [ $ret -eq 0 ]; then
         # Create a checkpoint file if database is successfully created
         # Populate the checkpoint file with the current date to avoid timing issue when using NFS persistence in multi-replica mode
         echo "$(date -Iseconds)" > "$ORACLE_BASE"/oradata/.${ORACLE_SID}"${CHECKPOINT_FILE_EXTN}"
         break
      elif [ $ret -eq 5 ]; then
         # PDB is in mounted state
         echo "PDB is in mounted state. Waiting for $i seconds."
         sleep $i
      else
         break
      fi
   done
  
  # Move database operational files to oradata
  moveFiles;

  # Execute setup script for extensions
  "$ORACLE_BASE"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/extensions/setup
  
  # Execute custom provided setup scripts
  "$ORACLE_BASE"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/setup

  # Setup TCPS with the database
  if [ "${ENABLE_TCPS}" = "true" ]; then
    "${ORACLE_BASE}"/"${CONFIG_TCPS_FILE}"
  fi

fi;

for i in 1 2 4 8; do
   # Check whether database is up and running
   IGNORE_DB_STARTED_MARKER=true "$ORACLE_BASE"/"$CHECK_DB_FILE"
   status=$?
   if [ $status -eq 5 ]; then
      # PDB is in mounted state
      echo "PDB is in mounted state. Waiting for $i seconds."
      sleep $i
   else
      break
   fi
done

# Check whether database is up and running
if [ $status -eq 0 ]; then
  echo "#########################"
  echo "DATABASE IS READY TO USE!"
  echo "#########################"

  # Execute startup script for extensions
  "$ORACLE_BASE"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/extensions/startup

  # Execute custom provided startup scripts
  "$ORACLE_BASE"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/startup
  
  # Create marker file for the health check
  touch "$DB_STARTED_MARKER_FILE"
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
