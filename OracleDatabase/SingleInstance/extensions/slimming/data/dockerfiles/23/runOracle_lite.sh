#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2023 Oracle and/or its affiliates. All rights reserved.
#
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Runs the Oracle Database inside the container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

############ Unzip datafiles ###########
function unzipOradata {

    echo "Expanding oracle data";
    cd "$ORACLE_BASE"/oradata;
    find . -name '*.gz' -print0 | xargs -0 -I {} -P 4 gunzip -f --fast {}
    cd -;

}

########### Symbolic link DB files ############
function symLinkFiles {

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

#unzip datafiles if not already present
if [ -d '/opt/oracle/oradata' ]; then
  # Find all ZIP files in the directory.
  zip_files=$(find "$ORACLE_BASE"/oradata -type f -name "*.zip")

  if [ ! -d "$ORACLE_BASE"/oradata/"${ORACLE_SID}" ]; then
    mv "$ORACLE_BASE"/tmp_oradata/* "$ORACLE_BASE"/oradata
    mv "$ORACLE_BASE"/tmp_oradata/.[!.]* "$ORACLE_BASE"/oradata
    unzipOradata
  elif [ -e  $zip_files ]; then
    # Datafile expansion incomplete
    unzipOradata
  fi
fi

if [ -d "$ORACLE_BASE"/tmp_oradata ]; then
  rm -rf "$ORACLE_BASE"/tmp_oradata
fi

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
    echo "Error: The container does not have enough memory allocated."
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

# Setting up ORACLE_PWD if podman secret is passed on
if [ -e '/run/secrets/oracle_pwd' ]; then
   ORACLE_PWD="$(cat '/run/secrets/oracle_pwd')"
   export ORACLE_PWD
fi

if [ "${ORACLE_SID}" != "FREE" ]; then
  echo "The ORACLE_SID cannot be changed (default value: FREE) for the Free Edition Containers."
  exit 1
fi;

# Default for ORACLE PDB
export ORACLE_PDB=${ORACLE_PDB:-FREEPDB1}

# Make ORACLE_PDB upper case
# Github issue # 984
export ORACLE_PDB=${ORACLE_PDB^^}

# Default for ORACLE CHARACTERSET
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}


# Check whether database already exists
if [ -f "$ORACLE_BASE"/oradata/."${ORACLE_SID}""${CHECKPOINT_FILE_EXTN}" ] && [ -d "$ORACLE_BASE"/oradata/"${ORACLE_SID}" ]; then
   symLinkFiles;

   # Make sure audit file destination exists
   if [ ! -d "$ORACLE_BASE"/admin/"$ORACLE_SID"/adump ]; then
     mkdir -p "$ORACLE_BASE"/admin/"$ORACLE_SID"/adump
   fi;

   # Start database
   $ORACLE_BASE/$START_FILE start

   # In case of the prebuiltdb extended image container, provision changing password by ORACLE_PWD
   if [ -n "${ORACLE_PWD}" ]; then
      "${ORACLE_BASE}"/"${PWD_FILE}" "${ORACLE_PWD}"
   fi

else
  echo "ERROR: Pre-built database not present."
  exit 1
fi;

# Check whether database is up and running
CHECK_DB_FILE="${CHECK_DB_FILE:-checkDBStatus.sh}"
"${ORACLE_BASE}/${CHECK_DB_FILE}"
status=$?

# Check whether database is up and running
if [ $status -eq 0 ]; then
  echo "#########################"
  echo "DATABASE IS READY TO USE!"
  echo "#########################"

  # Execute startup script for extensions
  "$ORACLE_BASE"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/extensions/startup

  # Execute custom provided startup scripts
  "$ORACLE_BASE"/"$USER_SCRIPTS_FILE" "$ORACLE_BASE"/scripts/startup

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
