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

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down database!"
   sqlplus sys/knl_test7 as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down database!"
   sqlplus sys/knl_test7 as sysdba <<EOF
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

"$ORACLE_BASE"/"$START_FILE";
status=$?

# Check whether database is up and running
if [ $status -eq 0 ]; then
  echo "#########################"
  echo "NANOVOS INSTANCE IS UP!"
  echo "#########################"
else
  echo "#####################################"
  echo "########### E R R O R ###############"
  echo "NANOVOS STARTUP WAS NOT SUCCESSFUL!"
  echo "Please check output for further info!"
  echo "########### E R R O R ###############" 
  echo "#####################################"
fi;

# Loop indefinitely (otherwise container will exit)
while true; do sleep 2; done
childPID=$!
wait $childPID

sleep 600000
