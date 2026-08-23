#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: Apr, 2024
# Author:paramdeep.saini@oracle.com
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

declare -x ORACLE_PWD
declare -x TRUE_CACHE_DB_UNIQUE_NAME
declare -x PRIMARY_DB_CONNECT_STR
declare -x PRIMARY_DB_NAME
declare -x DEBUG="TRUE"

export NOW=$(date +"%Y%m%d%H%M")
export TMP_LOC=${TMP_LOC:-"/var/tmp"}
export PRIMARY_DB_USER=${PRIMARY_DB_USER:-"sys as sysdba"}
export DB_PWD_FILE=${DB_PWD_FILE:-"oracle_pwd"}
export PWD_KEY=${PWD_KEY:-"oracle_pwd_privkey"}
export LOGDIR=${LOGDIR:-"/var/tmp"}
export LOGFILE="${LOGDIR}/tc_${NOW}.log"
export STD_OUT_FILE="/proc/1/fd/1"
export ORADATA="/opt/oracle/oradata"
export STD_ERR_FILE="/proc/1/fd/2"
declare -x SECRET_VOLUME='/run/secrets/'      ## Secret Volume
export TOP_PID=$$
rm -f $LOGFILE



#################################### Print and Exit Functions Begin Here #######################

function error_exit {
 local NOW=$(date +"%m-%d-%Y %T %Z")
 echo "${NOW} : ${PROGNAME}: ${1:-"Unknown Error"}" | tee -a $LOGFILE > $STD_OUT_FILE
 kill -s TERM $TOP_PID
}

function print_message {
   local NOW=$(date +"%m-%d-%Y %T %Z")
   # Display  message and return
   echo "${NOW} : ${PROGNAME} : ${1:-"Unknown Message"}" | tee -a $LOGFILE > $STD_OUT_FILE
   return $?
}

#################################### Print and Exit Functions End Here #######################

####################################### Functions Related to checks ##########################

#Function to check the required parameters for trueCache blob transfer 
function dbChecks {  
   #Checking if the ORACLE_HOME env variable is set
   if [ -z "$ORACLE_HOME" ]
      then
         error_exit "Set the ORACLE_HOME variable"
      else
      print_message "ORACLE_HOME set to $ORACLE_HOME"
      fi

      # If ORACLE_HOME path doesn't exist
      if [ ! -d "$ORACLE_HOME" ]
      then
         error_exit  "The ORACLE_HOME $ORACLE_HOME does not exist"
      else
         print_message "ORACLE_HOME Directory Exist"
   fi

   #Checking if the ORACLE_HOME env variable is set
   if [ ! -z "${ORACLE_SID}" ]; then
      print_message "ORACLE_SID set to ${ORACLE_SID}"
   else 
      error_exit "ORACLE_SID is not set. Exiting.."
   fi

   #Checking if the PDB_TC_SVCS env variable is set 
   if [ -z "$PDB_TC_SVCS" ]; then
      error_exit "PDB_TC_SVCS is not set. Exiting!"
   else
      print_message "PDB_TC_SVCS set to $PDB_TC_SVCS"
   fi
}

########################## Functions Related to checks Ends here #############################


##########################Functions Related to bussiness logic Ends here######################

# Function to set the connect string to the primary database 
function setConnectStr {
   read user priv <<< ${PRIMARY_DB_USER}
   local cpasswd=${ORACLE_PWD}
   local connectStr="${user}/${cpasswd}@${PRIMARY_DB_CONN_STR} ${priv}"
   PRIMARY_DB_CONNECT_STR=${connectStr}
}

# Resolve the source CDB name even when PRIMARY_DB_CONN_STR points at a service.
function resolvePrimaryDbName {
   local connect_str
   local output
   local resolved_db_name
   local resolved_db_unique_name

   read user priv <<< ${PRIMARY_DB_USER}
   connect_str="${user}/${ORACLE_PWD}@${PRIMARY_DB_CONN_STR} ${priv}"
   output=$(getSQLOUTPUT "SELECT name || ':' || db_unique_name FROM v\$database;" "${connect_str}")
   output=$(echo "${output}" | xargs)
   resolved_db_name=$(echo "${output}" | cut -d ':' -f 1)
   resolved_db_unique_name=$(echo "${output}" | cut -d ':' -f 2)

   if [ -z "${resolved_db_name}" ]; then
      error_exit "Unable to resolve PRIMARY_DB_NAME from PRIMARY_DB_CONN_STR ${PRIMARY_DB_CONN_STR}. Exiting..."
   fi

   if [ -n "${PRIMARY_DB_NAME}" ]; then
      print_message "PRIMARY_DB_NAME requested as ${PRIMARY_DB_NAME}"
      if [ "${PRIMARY_DB_NAME^^}" != "${resolved_db_name^^}" ]; then
         print_message "PRIMARY_DB_NAME ${PRIMARY_DB_NAME} does not match primary metadata db_name=${resolved_db_name} db_unique_name=${resolved_db_unique_name}. Using db_name ${resolved_db_name} for DBCA sourceDB."
      fi
   fi

   PRIMARY_DB_NAME="${resolved_db_name}"
   print_message "Resolved PRIMARY_DB_NAME=${PRIMARY_DB_NAME} db_unique_name=${resolved_db_unique_name}"
}

# Function to delete a file 
function delFile {
   local file_name=$1
   if [ -f "${file_name}" ]; then
      if [ "${DEBUG}" != "TRUE" ]; then
         rm -f "${file_name}"
      else
         print_message "delFile() : fname=[${file_name}]"
      fi
   fi
}

# Function to execute a sql script or sql query on a database
function getSQLOUTPUT {
   local sql_query=$1
   local connect_str=$2
   local type=$3
   local sql_script=$4
   local output
   if [ -z "${sql_query}" ]; then
      print_message "Empty sql_query passed to sqlplus. Operation Failed"
   fi

   if [ -z "${connect_str}" ]; then
      error_exit "Empty connect_str  passed to sqlplus. Operation Failed"
   fi

   if [ -z "${type}" ]; then
      type='notSet'
   fi

   if [ -z "${sql_script}" ]; then
      sql_script='notSet'
   fi

   if  [ "${type}" == "sqlScript" ] && [ -f ${sql_script} ]; then
      print_message "Executing sql script using connect string"
      output=$( "$ORACLE_HOME"/bin/sqlplus -s "$connect_str" << EOF >> $LOGFILE
      set heading off verify off echo off PAGESIZE 0
      @$sql_script
EOF
)
   else
output=$( "$ORACLE_HOME"/bin/sqlplus -s "${connect_str}" <<EOF
      set heading off feedback off verify off echo off PAGESIZE 0
      $sql_query
      exit
EOF
)
   fi
   echo  "${output}"
}

# Function to check if the blob file is present or not
function checkBlobFile {
   if [ ! -z "${TRUE_CACHE_BLOB}" ]; then
      print_message "True Cache Blob file location is passed and set to ${TRUE_CACHE_BLOB}"
      if [ ! -f "${TRUE_CACHE_BLOB}"  ]; then
         error_exit "True Cache Blob file ${TRUE_CACHE_BLOB} does not exist!"
      fi
      echo "${TRUE_CACHE_BLOB}"
   else
      print_message "Blob File will be generated automatically"
      TRUE_CACHE_BLOB=$(generateBlobFile)
      echo "${TRUE_CACHE_BLOB}"
   fi
}

# Function to execute the create blob file on the primary database 
function executeRemoteBlobFile {

   local blob_dir
   local job_action_file_name
   local sql_file
   local job_name
   local source_db
   local connect_str

   blob_dir=$1
   job_action_file_name=$2
   sql_file=$3
   job_name=$4
   source_db="${PRIMARY_DB_NAME}"
   connect_str=${PRIMARY_DB_CONNECT_STR}

   #### Execute the Blob-Remote file
   local sproc3="begin
            dbms_scheduler.create_job (job_name    => '${job_name}',
               job_type    => 'executable',
               job_action  => '${job_action_file_name}',
               number_of_arguments => 3,
               auto_drop   => TRUE);
            dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 1, argument_value => '${blob_dir}');
            dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 2, argument_value => '${source_db}');
            dbms_scheduler.set_job_argument_value(job_name => '${job_name}', argument_position => 3, argument_value => '${ORACLE_BASE}/${DECRYPT_PWD_FILE}');
            dbms_scheduler.run_job(job_name => '${job_name}',USE_CURRENT_SESSION => TRUE);
         end;
         /
   exec SYS.DBMS_SCHEDULER.DROP_JOB (job_name =>'${job_name}')
   "

   print_message "Executing shell script ${job_action_file_name} on primary database machine"
   echo "${sproc3}" > $sql_file
   output=$(getSQLOUTPUT "NULL" "${connect_str}" "sqlScript" "${sql_file}")
   print_message "Received Output: $output"
   delFile "${sql_file}"
}

# Function to generate the blob file on the primary database 
function generateBlobFile {
   local time_stamp
   local dir_name
   local blob_dir
   local job_name
   local table_name
   local blob_dir_name
   local connect_str
   local blob_zip_file_name
    
   
   time_stamp=$(date '+%Y%m%d%H%M%S')
   dir_name=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-7} | head -n 1)
   blob_dir="${TMP_LOC}/blob${dir_name}"
   job_name="bjob$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-7} | head -n 1)${time_stamp}"
   table_name="tab$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-5} | head -n 1)"
   cpasswd="${ORACLE_PWD}"
   blob_dir_name="blob$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-5} | head -n 1)"
   connect_str=${PRIMARY_DB_CONNECT_STR}
   blob_zip_file_name="blobTestData.tar.gz"


   #### Execute the Remote file
   executeRemoteBlobFile "${blob_dir}" "${ORACLE_BASE}/${CREATE_BLOB_SCRIPT}" "${TMP_LOC}/tc_sqlquery1.sql" "${job_name}"

   ###### Create Blob in primary Database
   sproc="create or replace directory ${blob_dir_name^^} as '${blob_dir}';
   CREATE TABLE ${table_name} (FILE_ZIP BLOB);
   DECLARE
         oNew     BLOB;
         oBFile   BFILE;
      BEGIN
         oBFile := BFILENAME('${blob_dir_name^^}', '${blob_zip_file_name}');
         DBMS_LOB.OPEN(oBFile, DBMS_LOB.LOB_READONLY);
         DBMS_LOB.createtemporary(oNew,TRUE);
         DBMS_LOB.LOADFROMFILE(oNew, oBFile, dbms_lob.lobmaxsize);
         DBMS_LOB.CLOSE(oBFile);
         INSERT INTO ${table_name}  VALUES ( oNew );
         dbms_lob.freetemporary(oNew);     
      END;
   /
   "

   print_message "Creating BLOB table on ${table_name} primary database machine to create blob of blobfile"
   echo "${sproc}" > ${TMP_LOC}/tc_sqlquery2.sql
   output=$(getSQLOUTPUT "NULL" "${connect_str}" "sqlScript" "${TMP_LOC}/tc_sqlquery2.sql")
   print_message "Received Output: $output"
   delFile "${TMP_LOC}/tc_sqlquery2.sql"

   status=$(copyRemoteBlobFile  "${table_name}" "${TMP_LOC}/${blob_dir_name}" "${blob_zip_file_name}")

   if [ -f "${TMP_LOC}/${blob_dir_name}/${blob_zip_file_name}" ]; then
      print_message "Blob File generated ${TMP_LOC}/${blob_dir_name}/${blob_zip_file_name}"
   else
   error_exit "Blob file generate failed. Exiting..."
   fi

   echo "${TMP_LOC}/${blob_dir_name}/${blob_zip_file_name}"
}

# Function to the copy the blob file from the primary database 
function copyRemoteBlobFile {
   local tablename=$1
   local dirloc=$2
   local blobfile=$3

   /bin/mkdir -p "${dirloc}"
   $ORACLE_HOME/python/bin/python "${ORACLE_BASE}/${BLOBREADER}" "${PRIMARY_DB_CONN_STR}"  "${ORACLE_PWD}" "${tablename}" "${dirloc}/${blobfile}"
}

#####################################
#####  MAIN #########################
#####################################

if [ -f "$ORACLE_BASE"/oradata/.${ORACLE_SID}"${CHECKPOINT_FILE_EXTN}" ]; then
   # On pod restarts the PVC can already contain the created marker. Preserve any
   # blob path the caller provided so the main startup path keeps using it.
   if [ -n "${TRUE_CACHE_BLOB}" ]; then
      echo "${TRUE_CACHE_BLOB}"
   fi
   exit 0
fi

# Check if the database if the pre-requisites for truecache auto flow is satisfied or not
dbChecks

# Preserve an already supplied blob path without forcing password decrypt or
# primary SQL connectivity. Those lookups are only needed when we must
# generate the blob on demand.
if [ -n "${TRUE_CACHE_BLOB}" ]; then
   checkBlobFile
   exit 0
fi

# Storing hte decrypted oracle password
ORACLE_PWD=$($ORACLE_BASE/$DECRYPT_PWD_FILE)
resolvePrimaryDbName
# Set connect strings for the database
setConnectStr
# Check if the blob file is already present; if not present then create and transfer the blob file from primary
checkBlobFile
