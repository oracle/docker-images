#!/bin/bash

#############################
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

export CLONED_FILE="status_completed"
export STANDBY_STATUS="status_completed"

########### Clone Files #####################
function cloneDB {

export NEW_ORACLE_SID=$ORACLE_SID
export ORACLE_SID=$OLD_ORACLE_SID
sqlplus / as sysdba << EOF
   STARTUP mount;
   exit;
EOF

echo 'Y' | nid target=/ dbname=$NEW_ORACLE_SID

if [ $? -eq 0 ]; then
 echo "DB name changed sucessfully"
else
 echo "DB name change process failed"
 exit 1;
fi

echo "Changing DB name"
export ORACLE_SID=$NEW_ORACLE_SID
sqlplus / as sysdba << EOF
   STARTUP nomount;
   alter system set db_name=$ORACLE_SID scope=spfile;
   shutdown immediate
   exit;
EOF

echo "Changing OLD SID string to new string"
sed -i "s/$OLD_ORACLE_SID/$ORACLE_SID/g" $ORACLE_HOME/network/admin/tnsnames.ora
sed -i "s/$OLD_ORACLE_PDB/$ORACLE_PDB/g" $ORACLE_HOME/network/admin/tnsnames.ora

echo "Starting Listener"

$ORACLE_HOME/bin/lsnrctl start

echo "Starting new cloned DB"

sqlplus / as sysdba << EOF
   STARTUP mount;
   alter database open resetlogs;
   exit;
EOF

echo "Renaming PDB"

sqlplus / as sysdba << EOF
   alter pluggable database $OLD_ORACLE_PDB open restricted;
   alter session set container=$OLD_ORACLE_PDB;
   alter pluggable database rename global_name to $ORACLE_PDB;
   exit;
EOF

echo " CLosing and Opening PDB"

sqlplus / as sysdba << EOF
   alter pluggable database $ORACLE_PDB close immediate; 
   alter pluggable database $ORACLE_PDB open;
   alter system register;
   exit;
EOF


echo "Touching $CLONED_FILE as setup is  completed"
touch $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/$CLONED_FILE

}


############################################

########### Symbolic link DB files ############
function symLinkFiles {

   # Make sure audit file destination exists
   if [ ! -d $ORACLE_BASE/admin/$ORACLE_SID/adump ]; then
      mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
   fi;

   if [ -L $ORACLE_HOME/dbs/spfile$OLD_ORACLE_SID.ora ]; then
     unlink $ORACLE_HOME/dbs/spfile$OLD_ORACLE_SID.ora
   fi;
   if [ -L $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora ]; then
     unlink $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
   fi;
   if [ -L $ORACLE_HOME/dbs/orapw$OLD_ORACLE_SID ]; then
      unlink $ORACLE_HOME/dbs/orapw$OLD_ORACLE_SID
   fi;
   if [ -L $ORACLE_HOME/dbs/orapw$ORACLE_SID ]; then
     unlink $ORACLE_HOME/dbs/orapw$ORACLE_SID
   fi;
   if [ -L $ORACLE_HOME/network/admin/sqlnet.ora ]; then
      unlink $ORACLE_HOME/network/admin/sqlnet.ora
   fi;
   if [ -L $ORACLE_HOME/network/admin/listener.ora ]; then
     unlink $ORACLE_HOME/network/admin/listener.ora 
   fi;
   if [ -L $ORACLE_HOME/network/admin/tnsnames.ora ]; then
      unlink $ORACLE_HOME/network/admin/tnsnames.ora
   fi
   if [ -L $ORACLE_HOME/dbs/dr1$ORACLE_SID ]; then
     unlink $ORACLE_HOME/dbs/dr1$ORACLE_SID
   fi;
   if [ -L $ORACLE_HOME/dbs/dr2$ORACLE_SID ]; then
      unlink $ORACLE_HOME/dbs/dr2$ORACLE_SID 
   fi;
 
   if [ -f $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/spfile$OLD_ORACLE_SID.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/spfile$OLD_ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$OLD_ORACLE_SID.ora
      ## Link based on ORACLE_BASE
      ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/spfile$OLD_ORACLE_SID.ora $ORACLE_BASE/dbs/spfile$OLD_ORACLE_SID.ora
   fi;

   if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora 
      ## Link based on ORACLE_BASE
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora $ORACLE_BASE/dbs/spfile$ORACLE_SID.ora
   else
     if [ ! -z ${CLONE_DB} ]; then
       if [ ${CLONE_DB^^} == "TRUE" ]; then
          ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/spfile$OLD_ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
          ## Link based on ORACLE_BASE
          ln -s  $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/spfile$OLD_ORACLE_SID.ora  $ORACLE_BASE/dbs/spfile$ORACLE_SID.ora
       fi
     fi
   fi;

   if [ -f $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/orapw$OLD_ORACLE_SID ]; then
          ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/orapw$OLD_ORACLE_SID $ORACLE_HOME/dbs/orapw$OLD_ORACLE_SID
          ## Link based on ORACLE_BASE
          ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/orapw$OLD_ORACLE_SID $ORACLE_BASE/dbs/orapw$OLD_ORACLE_SID
   fi;

   if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID ]; then
       ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID $ORACLE_HOME/dbs/orapw$ORACLE_SID
       ## Link based on ORACLE_BASE
       ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID $ORACLE_BASE/dbs/orapw$ORACLE_SID
   else
     if [ ! -z ${CLONE_DB} ]; then
       if [ ${CLONE_DB^^} == "TRUE" ]; then
         ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/orapw$OLD_ORACLE_SID $ORACLE_HOME/dbs/orapw$ORACLE_SID
         ## Link based on ORACLE_BASE
         ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/orapw$OLD_ORACLE_SID $ORACLE_BASE/dbs/orapw$ORACLE_SID 
       fi
     fi
   fi;

   if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/sqlnet.ora ]; then
       ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora
   else
     if [ ! -z ${CLONE_DB} ]; then
       if [ ${CLONE_DB^^} == "TRUE" ]; then
          ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora
       fi
     fi
   fi;

   if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/listener.ora ]; then
       ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/listener.ora $ORACLE_HOME/network/admin/listener.ora
   else
     if [ ! -z ${CLONE_DB} ]; then
       if [ ${CLONE_DB^^} == "TRUE" ]; then
         ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/listener.ora $ORACLE_HOME/network/admin/listener.ora
       fi
     fi
   fi;

   if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/listener.ora ]; then
       ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora
   else
     if [ ! -z ${CLONE_DB} ]; then
       if [ ${CLONE_DB^^} == "TRUE" ]; then
         ln -s $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora
       fi
     fi
   fi;

   if [ -f $ORACLE_HOME/dbs/dr1$ORACLE_SID ]; then
          ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/dr1$ORACLE_SID $ORACLE_HOME/dbs/dr1$ORACLE_SID
   fi;

   if [ -f $ORACLE_HOME/dbs/dr2$ORACLE_SID ]; then
          ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/dr2$ORACLE_SID $ORACLE_HOME/dbs/dr2$ORACLE_SID
   fi;

   if [ ! -d $ORACLE_BASE/oradata/$ORACLE_SID ]; then
       mkdir -p $ORACLE_BASE/oradata/$ORACLE_SID
   fi;

 if [ ! -z ${CLONE_DB} ]; then
  if [ ${CLONE_DB^^} == "TRUE" ]; then
   if [ ! -L $ORACLE_BASE/oradata/$ORACLE_SID/$ORACLE_PDB ]; then
      ln -s $ORACLE_BASE/oradata/$OLD_ORACLE_SID/$OLD_ORACLE_PDB $ORACLE_BASE/oradata/$ORACLE_SID/$ORACLE_PDB 
   fi;
   # oracle user does not have permissions in /etc, hence cp and not ln 
   sed -i "s/$OLD_ORACLE_SID/$ORACLE_SID/g" $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/oratab
   cp $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/oratab /etc/oratab
 fi
fi

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

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown abort;
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
# Github issue #219: Prevent integer overflow,
# only check if memory digits are less than 11 (single GB range and below) 
if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes | wc -c` -lt 11 ]; then
   if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` -lt 2147483648 ]; then
      echo "Error: The container doesn't have enough memory allocated."
      echo "A database container needs at least 2 GB of memory."
      echo "You currently only have $((`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`/1024/1024/1024)) GB allocated to the container."
      exit 1;
   fi;
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

# Set SIGKILL handler
trap _kill SIGKILL

# Default for ORACLE SID
if [ "$OLD_ORACLE_SID" == "" ]; then
   export OLD_ORACLE_SID=SEEDCDB
fi

if [ ! -z ${ORACLE_SID} ]; then
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
else
     echo "Error: The ORACLE_SID must be defined."
     exit 1;
fi;


if [ ! -z ${ORACLE_PDB} ]; then
  export ORACLE_PDB=${ORACLE_PDB^^}

  if [ "${#ORACLE_PDB}" -gt 12 ]; then
     echo "Error: The ORACLE_PDB must only be up to 12 characters long."
     exit 1;
  fi;
else
     echo "Error: The ORACLE_PDB must be defined."
     exit 1;
fi;

if [ ! -z ${OLD_ORACLE_PDB} ]; then
  export OLD_ORACLE_PDB=${OLD_ORACLE_PDB^^}
else
  export OLD_ORACLE_PDB=SEEDPDB
fi;


# Default for ORACLE CHARACTERSET
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}

# Check whether database already exists
if [ ! -z ${CLONE_DB} ]; then
if [ ${CLONE_DB^^} == "TRUE" ]; then
echo "CLONE_DB is set to true, cloning DB from seed"
if [ -d $ORACLE_BASE/oradata/$OLD_ORACLE_SID ]; then
   symLinkFiles;
   
   # Make sure audit file destination exists
   if [ ! -d $ORACLE_BASE/admin/$OLD_ORACLE_SID/adump ]; then
      mkdir -p $ORACLE_BASE/admin/$OLD_ORACLE_SID/adump
   fi;

   # Make sure audit file destination exists
   if [ ! -d $ORACLE_BASE/admin/$ORACLE_SID/adump ]; then
      mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
   fi;
  
   if [ -f $ORACLE_BASE/oradata/dbconfig/$OLD_ORACLE_SID/$CLONED_FILE ];
   then
       # Start database
       echo "Starting Database as cloned status file exist"
       $ORACLE_BASE/$START_FILE;
   else
       echo "Performing Cloning as cloned status file does not exist"
       cloneDB;
   fi
else
     echo "Error: The $ORACLE_BASE/oradata/$OLD_ORACLE_SID (ORACLE_BASE/oradata/OLD_ORACLE_SID) dir does not exist. Error exiting ."
     exit 1;
fi
fi
fi

if [ ${OP_TYPE,,} == "standbyshard" ]; then
   symLinkFiles;
   if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/$STANDBY_STATUS ];
   then
       # Start database
       echo "Starting Database as standby setup status file exist"
       $ORACLE_BASE/$START_FILE;
   fi
fi   

#This is the main file which calls other file to setup the sharding.
if [ -z ${BASE_DIR} ]; then
    BASE_DIR=/opt/oracle/scripts/setup
fi

if [ -z ${MAIN_SCRIPT} ]; then
    SCRIPT_NAME="main.py"
fi

if [ -z ${EXECUTOR} ]; then
    EXECUTOR="python"
fi

cd $BASE_DIR
$EXECUTOR $SCRIPT_NAME
