#!/bin/bash
#
# LICENSE UPL 1.0
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description:
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# shellcheck disable=SC2155
# shellcheck disable=SC2283
# shellcheck disable=SC2034
# shellcheck disable=SC2068
# shellcheck disable=SC2184

export NOW=$(date +"%Y%m%d%H%M")
export LOGDIR="/tmp"
export LOGFILE="${LOGDIR}/oshard_${NOW}.log"
export STD_OUT_FILE="/proc/1/fd/1"
export STD_ERR_FILE="/proc/1/fd/2"
declare -x SECRET_VOLUME='/run/secrets/'      ## Secret Volume
declare -x PWD_KEY='pwd.key'                  ## PWD Key File
declare -x COMMON_OS_PWD_FILE='common_os_pwdfile.enc'
declare -x DB_PWD_FILE
export PDB_SQL_SCRIPT="/tmp/pdb.sql"
export TOP_PID=$$
rm -f /tmp/sqllog.output
rm -f $PDB_SQL_SCRIPT
rm -f $LOGFILE

#################################### Print and Exit Functions Begin Here #######################
error_exit() {
local NOW=$(date +"%m-%d-%Y %T %Z")
        # Display error message and exit
#       echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        echo "${NOW} : ${PROGNAME}: ${1:-"Unknown Error"}" | tee -a $LOGFILE > $STD_OUT_FILE
        kill -s TERM $TOP_PID
}

print_message ()
{
        local NOW=$(date +"%m-%d-%Y %T %Z")
        # Display  message and return
        echo "${NOW} : ${PROGNAME} : ${1:-"Unknown Message"}" | tee -a $LOGFILE > $STD_OUT_FILE
        return $?
}
#################################### Print and Exit Functions End Here #######################


####################################### Functions Related to checks ####################
dbChecks()
{
if [ -z "$ORACLE_HOME" ]
then
  error_exit "Set the ORACLE_HOME variable"
else
  print_message "ORACLE_HOME set to $ORACLE_HOME"
fi

# If ORACLE_HOME doesn't exist #
if [ ! -d "$ORACLE_HOME" ]
then
         error_exit  "The ORACLE_HOME $ORACLE_HOME does not exist"
else
         print_message "ORACLE_HOME Directory Exist"
fi

##################  Checks for Password and Clustername and clustertype begins here ###########
if [ -f "${SECRET_VOLUME}/${COMMON_OS_PWD_FILE}" ]; then
cmd='openssl enc -d -aes-256-cbc -in "${SECRET_VOLUME}/${COMMON_OS_PWD_FILE}" -out /tmp/${COMMON_OS_PWD_FILE} -pass file:"${SECRET_VOLUME}/${PWD_KEY}"'

eval $cmd

if [ $? -eq 0 ]; then
print_message "Password file generated"
else
error_exit "Error occurred during common os password file generation"
fi

read PASSWORD < /tmp/${COMMON_OS_PWD_FILE}
rm -f /tmp/${COMMON_OS_PWD_FILE}
else
 print_message "Password is empty string"
 export PASSWORD=O$(openssl rand -base64 6 | tr -d "=+/")_1
fi

if [ -z "${ORACLE_PWD}" ]; then
  print_message "Setting ORACLE_PWD to PASSWORD passed from encrypted files"
  export ORACLE_PWD=${PASSWORD}
else
 print_message "ORACLE_PWD is set to user specified password"
fi

###################################################################################################


if [ -z "${SHARD_ADMIN_USER}" ]
then
  print_message "SHARD_ADMIN_USER is not set, setting default to mysdbadmin"
  export SHARD_ADMIN_USER="mysdbadmin"
else
 print_message "SHARD_ADMIn_USER set to $SHARD_ADMIN_USER"
fi


if [ -z "${PDB_ADMIN_USER}" ]
then
  print_message "PDB_ADMIN_USER is not set, setting default to PDBADMIN"
  export PDB_ADMIN_USER="pdbadmin"
else
 print_message "PDB_ADMIN_USER set to $PDB_ADMIN_USER"
fi


# Validate the value of ORACLE_SID #
if [ -z "${ORACLE_SID}" ]
then
        error_exit "Set the ORACLE_SID variable"
else
        print_message "ORACLE_SID is set to $ORACLE_SID"
fi

if [ -z "${ORACLE_HOSTNAME}" ]
then
 if [ -z "${KUBE_SVC}" ]; then
       print_message "ORACLE_HOSTNAME variable is not set"
       export ORACLE_HOSTNAME="$(hostname)"
       print_message "ORACLE_HOSTNAME is set to $ORACLE_HOSTNAME"
   else
       print_message "ORACLE_HOSTNAME variable is not set"
       export ORACLE_HOSTNAME="$(hostname).${KUBE_SVC}"
       print_message "ORACLE_HOSTNAME is set to $ORACLE_HOSTNAME"
 fi
else
       print_message "ORACLE_HOSTNAME is set to $ORACLE_HOSTNAME"
fi



if [ -z "$DB_PORT" ]
then
        print_message  "Set the DB_PORT variable"
        export DB_PORT=1521
else
        print_message "DB Port is set to $DB_PORT"
fi

if [ -z "${DB_RECOVERY_FILE_DEST}" ]; then
        print_message  "Set the DB_RECOVERY_FILE_DEST is not set"
        export DB_RECOVERY_FILE_DEST="${ORACLE_BASE}/oradata/fast_recovery_area/${ORACLE_SID}"
fi

if [ -z "${DB_CREATE_FILE_DEST}" ]; then
        print_message  "Set the DB_CREATE_FILE_DEST is not set. Setting to ${ORACLE_BASE}/oradata/${ORACLE_SID}"
        export DB_CREATE_FILE_DEST="${ORACLE_BASE}/oradata/${ORACLE_SID}"
fi

if [ -z "${DATA_PUMP_DIR}" ]; then
        print_message  "DATA_PUMP_DIR is not set, it will se to ${ORACLE_BASE}/oradata/data_pump_dir"
        export DATA_PUMP_DIR="${ORACLE_BASE}/oradata/data_pump_dir"
fi

if [ ! -d "${DATA_PUMP_DIR}" ]; then
        print_message  "DATA_PUMP_DIR ${DATA_PUMP_DIR} directory does not exist"
        mkdir -p "${DATA_PUMP_DIR}"
fi

if [ ! -d "${DB_RECOVERY_FILE_DEST}" ]; then
        print_message  "DB_RECOVERY_FILE_DEST ${DB_RECOVERY_FILE_DEST} directory does not exist"
        mkdir -p "${DB_RECOVERY_FILE_DEST}"
fi

if [ -z "${DB_RECOVERY_FILE_DEST_SIZE}" ]; then
        print_message  "DB_RECOVERY_FILE_DEST_SIZE is  not set"
        export DB_RECOVERY_FILE_DEST_SIZE="40G"
else
     print_message  "DB_RECOVERY_FILE_DEST_SIZE is set to ${DB_RECOVERY_FILE_DEST_SIZE}"
fi

}

gsmChecks()
{
 print_message "Performing GSM related checks"

if [ ! -z "${KUBE_SVC}" ]; then
  lordinal=$( hostname | awk -F "-" '{ print $NF }' )
  print_message "lordinal is set to ${lordinal}"
  region_num=$((lordinal+1))
  if [ -z "${REGION}" ]; then
        print_message  "REGION is not set. Setting to region$lordinal"
        export REGION="region${region_num}"
  fi
else
  if [ -z "${REGION}" ]; then
        error_exit "REGION Canot be set to empty"
  fi
fi 

##################  Checks for Password and Clustername and clustertype begins here ###########
if [ -f "${SECRET_VOLUME}/${COMMON_OS_PWD_FILE}" ]; then
cmd='openssl enc -d -aes-256-cbc -in "${SECRET_VOLUME}/${COMMON_OS_PWD_FILE}" -out /tmp/${COMMON_OS_PWD_FILE} -pass file:"${SECRET_VOLUME}/${PWD_KEY}"'

eval $cmd

if [ $? -eq 0 ]; then
print_message "Password file generated"
else
error_exit "Error occurred during common os password file generation"
fi

read PASSWORD < /tmp/${COMMON_OS_PWD_FILE}
rm -f /tmp/${COMMON_OS_PWD_FILE}
else
 print_message "Password is empty string"
 export PASSWORD=O$(openssl rand -base64 6 | tr -d "=+/")_1
fi

if [ -z "${ORACLE_PWD}" ]; then
  print_message "Setting ORACLE_PWD to PASSWORD passed from encrypted files"
  export ORACLE_PWD=${PASSWORD}
else
 print_message "ORACLE_PWD is set to user specified password"
fi

###################################################################################################

if [ -z "$SHARD_ADMIN_USER" ]
then
  print_message "SHARD_ADMIN_USER is not set, setting default to mysdbadmin"
  export SHARD_ADMIN_USER="mysdbadmin"
else
 print_message "SHARD_ADMIn_USER set to $SHARD_ADMIN_USER"
fi


if [ -z "$PDB_ADMIN_USER" ]
then
  print_message "PDB_ADMIN_USER is not set, setting default to PDBADMIN"
  export PDB_ADMIN_USER="pdbadmin"
else
 print_message "PDB_ADMIN_USER set to $PDB_ADMIN_USER"
fi


if [ -z "${SHARD_GROUP_NAME}" ]; then
        print_message  "SHARD_GROUP_NAME is not set, it will be set to primary_shardgroup"
        export SHARD_GROUP_NAME="primary_shardgroup"
fi

if [ -z "${SHARD_DEPLOYMENT_TYPE}" ]; then
        print_message  "SHARD_DEPLOYMENT_TYPE is not set, it will set to primary"
        export SHARD_DEPLOYMENT_TYPE="primary"
fi

if [ -z "${SHARD_DIRECTOR_NAME}" ]; then
        print_message  "SHARD_DIRECTOR_NAME is not set, it will set to sharddirector${region_num}"
        export SHARD_DIRECTOR_NAME="sharddirector${region_num}"
fi

if [ -z "${ORACLE_HOSTNAME}" ]
then
 if [ -z "${KUBE_SVC}" ]; then
       print_message "ORACLE_HOSTNAME variable is not set"
       export ORACLE_HOSTNAME="$(hostname)"
       print_message "ORACLE_HOSTNAME is set to $ORACLE_HOSTNAME"
   else
       print_message "ORACLE_HOSTNAME variable is not set"
       export ORACLE_HOSTNAME="$(hostname).${KUBE_SVC}"
       print_message "ORACLE_HOSTNAME is set to $ORACLE_HOSTNAME"
 fi
else
       print_message "ORACLE_HOSTNAME is set to $ORACLE_HOSTNAME"
fi

}

###################################### Function Related to Check end here ###################

################################### Reset Password ###########################################
resetPassword()
{
if [ -f "${HOME}/setPassword.sh" ]; then
if [ ! -z "${ORACLE_PWD}" ]; then
"${HOME}"/setPassword.sh "$ORACLE_PWD"
fi
fi
}

###############################################################################################
setupCatalog()
{

localconnectStr="/ as sysdba"
systemStr="system/${ORACLE_PWD}"
sqlScript="/tmp/setapp.sql"
print_message "Setting up Paramteres in Spfile"

cmd1="drop table shardsetup;"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$systemStr"

cmd1="alter system set db_create_file_dest=\"${DB_CREATE_FILE_DEST}\" scope=both;"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"

cmd1="alter system set db_recovery_file_dest_size=${DB_RECOVERY_FILE_DEST_SIZE} scope=both;"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"

cmd1="alter system set db_recovery_file_dest=\"${DB_RECOVERY_FILE_DEST}\" scope=both;"
#cmd=$( eval echo "$cmd1" )
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL "$cmd1" "$localconnectStr"


cmd1="alter system set open_links=16 scope=spfile;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter system set open_links_per_instance=16 scope=spfile;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="@$ORACLE_HOME/rdbms/admin/setCatalogDBPrivs.sql;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"
print_message "cat /tmp/setup_grants_privs.lst"

cmd1="alter user gsmcatuser account unlock;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter user gsmcatuser identified by $ORACLE_PWD;"
print_message "Sending query to sqlplus to execute alter user gsmcatuser identified by ORACLE_PWD;"
executeSQL  "$cmd1"   "$localconnectStr"


#cmd1="alter system set remote_listener=\"\(ADDRESS=\(HOST=$ORACLE_HOSTNAME\)\(PORT=$DB_PORT\)\(PROTOCOL=tcp\)\)\";"
cmd1="alter system set remote_listener=\"(ADDRESS=(HOST=$ORACLE_HOSTNAME)(PORT=$DB_PORT)(PROTOCOL=tcp))\" scope=both;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"



cmd1="shutdown immediate;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="startup mount;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database archivelog;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database open;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database flashback on;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database force logging;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL "$cmd1", "$localconnectStr"

cmd1="ALTER PLUGGABLE DATABASE ALL OPEN;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL "$cmd1"  "$localconnectStr"

if [ ! -z "${ORACLE_PDB}" ]; then
setupCatalogPDB
fi

cmd1="create table shardsetup (status varchar2(10));"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL "$cmd1" "$systemStr"

cmd1="insert into shardsetup values('completed');"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL "$cmd1" "$systemStr"
}

configureSampleAppSchema()
{
local sqlScript="/tmp/sqlScript.sql"
connectStr = "${SHARD_ADMIN_USER}/${ORACLE_PWD}"

echo  "alter session enable shard ddl;" > ${sqlScript}
echo  "create user app_schema identified by '&1';" >> ${sqlScript}
echo  "grant all privileges to app_schema;" >> ${sqlScript}
echo  "grant gsmadmin_role to app_schema;" >> ${sqlScript}
echo  "grant select_catalog_role to app_schema;" >> ${sqlScript}
echo  "grant connect, resource to app_schema;" >> ${sqlScript}
echo  "grant dba to app_schema;" >> ${sqlScript}
echo  "grant execute on dbms_crypto to app_schema;" >> ${sqlScript}
echo "CREATE TABLESPACE SET TSP_SET_1 using template (datafile size 100m autoextend on next 10M maxsize unlimited  extent management local segment space management auto);" >> ${sqlScript}
echo "CREATE TABLESPACE SET LOBTS1;" >> ${sqlScript}
echo "CREATE TABLESPACE products_tsp datafile size 100m autoextend on next 10M maxsize unlimited extent management local uniform size 1m; "  >> ${sqlScript}
echo "CONNECT app_schema/'&1';" >> ${sqlScript}
echo "ALTER SESSION ENABLE SHARD DDL;" >> ${sqlScript}
echo "CREATE SHARDED TABLE Customers (CustId      VARCHAR2(60) NOT NULL, FirstName   VARCHAR2(60), LastName    VARCHAR2(60), Class       VARCHAR2(10), Geo         VARCHAR2(8),CustProfile VARCHAR2(4000),Passwd      RAW(60),CONSTRAINT pk_customers PRIMARY KEY (CustId),CONSTRAINT json_customers CHECK (CustProfile IS JSON)) TABLESPACE SET TSP_SET_1  PARTITION BY CONSISTENT HASH (CustId) PARTITIONS AUTO;" >> ${sqlScript}
echo "CREATE SHARDED TABLE Orders (OrderId     INTEGER NOT NULL,CustId      VARCHAR2(60) NOT NULL, OrderDate   TIMESTAMP NOT NULL,SumTotal    NUMBER(19,4),Status      CHAR(4), CONSTRAINT  pk_orders PRIMARY KEY (CustId, OrderId),CONSTRAINT  fk_orders_parent FOREIGN KEY (CustId)    REFERENCES Customers ON DELETE CASCADE  ) PARTITION BY REFERENCE (fk_orders_parent);" >> ${sqlScript}
echo "CREATE SEQUENCE Orders_Seq;" >> ${sqlScript}
echo "CREATE SHARDED TABLE LineItems (OrderId     INTEGER NOT NULL,CustId      VARCHAR2(60) NOT NULL,ProductId   INTEGER NOT NULL,Price       NUMBER(19,4),Qty         NUMBER,CONSTRAINT  pk_items PRIMARY KEY (CustId, OrderId, ProductId),CONSTRAINT  fk_items_parent FOREIGN KEY (CustId, OrderId)    REFERENCES Orders ON DELETE CASCADE  ) PARTITION BY REFERENCE (fk_items_parent);" >> ${sqlScript}
echo "CREATE DUPLICATED TABLE Products (ProductId  INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,Name       VARCHAR2(128),DescrUri   VARCHAR2(128),LastPrice  NUMBER(19,4)) TABLESPACE products_tsp;"  >> ${sqlScript}

print_message "Executing sql script ${sqlScript}"
cat ${sqlScript} >> $LOGFILE
executeSQL "$cmd1"  "$connectStr" "sqlScript" "${sqlScript}"

}


setupCatalogPDB()
{
#pdbConnStr="${PDB_ADMIN_USER}/${ORACLE_PWD}@//${ORACLE_HOSTNAME}:1521/${ORACLE_PDB}"
pdbConnStr=" /as sysdba"

local sqlScript="/tmp/sqlScript.sql"

print_message "Settup Sql Script to setup Catalog PDB"
echo  "alter session set container=${ORACLE_PDB};" > "${sqlScript}"
echo  "create user ${SHARD_ADMIN_USER} identified by ${ORACLE_PWD};" >> "${sqlScript}"
echo  "grant connect, create session, gsmadmin_role to ${SHARD_ADMIN_USER} ;" >> "${sqlScript}"
echo  "grant inherit privileges on user SYS to GSMADMIN_INTERNAL;" >> "${sqlScript}"
echo  "execute dbms_xdb.sethttpport(8080);" >> ${sqlScript}
echo  "exec DBMS_SCHEDULER.SET_AGENT_REGISTRATION_PASS('${ORACLE_PWD}');" >> "${sqlScript}"

print_message "Executing sql script ${sqlScript}"
cat ${sqlScript} >> $LOGFILE
executeSQL "$cmd1"   "${pdbConnStr}" "sqlScript" "${sqlScript}"
}

######################################################################## Catalog Setup task ends here #################################

######################################################################## Primary Shard Setup task ends here #################################

setupShardPDB()
{

#pdbConnStr="${PDB_ADMIN_USER}/${ORACLE_PWD}@//${ORACLE_HOSTNAME}:1521/${ORACLE_PDB}"
pdbConnStr=" /as sysdba"

local sqlScript="/tmp/sqlScript.sql"
print_message "Settup Sql Script to setup Catalog PDB"
echo  "alter session set container=${ORACLE_PDB};" > "${sqlScript}"
echo  "grant read,write on directory DATA_PUMP_DIR to GSMADMIN_INTERNAL;" >> "${sqlScript}"
echo  "grant sysdg to GSMUSER;" >> "${sqlScript}"
echo  "grant sysbackup to GSMUSER;" >> "${sqlScript}"
echo  "execute DBMS_GSM_FIX.validateShard;" >> ${sqlScript}
print_message "Executing sql script ${sqlScript}"
cat ${sqlScript} >> $LOGFILE
executeSQL "$cmd1" "${pdbConnStr}" "sqlScript" "${sqlScript}"

}

setupShardCDB()
{
localconnectStr="/as sysdba"
systemStr="system/${ORACLE_PWD}"
print_message "Setting up Paramteres in Spfile"

cmd1="drop table shardsetup;"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$systemStr"

cmd1="alter system set db_create_file_dest=\"${DB_CREATE_FILE_DEST}\" scope=both;"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"

cmd1="alter system set db_recovery_file_dest_size=${DB_RECOVERY_FILE_DEST_SIZE} scope=both;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"

cmd1="alter system set db_recovery_file_dest=\"${DB_RECOVERY_FILE_DEST}\" scope=both;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter system set open_links=16 scope=spfile;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter system set open_links_per_instance=16 scope=spfile;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter user gsmrootuser account unlock;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter user gsmrootuser identified by ${ORACLE_PWD}  container=all;"
print_message "Sending query to sqlplus to execute alter user gsmrootuser identified by ORACLE_PWD  container=all;"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="grant sysdg to gsmrootuser;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="grant sysbackup to gsmrootuser;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter user GSMUSER account unlock;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter user GSMUSER identified by ${ORACLE_PWD} container=all;"
print_message "Sending query to sqlplus to execute alter user GSMUSER identified by ORACLE_PWD container=all;"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="grant sysdg to GSMUSER;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="grant sysbackup to GSMUSER;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter system set dg_broker_start=true scope=both;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="create or replace directory DATA_PUMP_DIR as '${DATA_PUMP_DIR}';"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="grant read,write on directory DATA_PUMP_DIR to GSMADMIN_INTERNAL;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


#cmd1="alter system set remote_listener=\"\(ADDRESS=\(HOST=$ORACLE_HOSTNAME\)\(PORT=$DB_PORT\)\(PROTOCOL=tcp\)\)\";"
cmd1="alter system set remote_listener=\"(ADDRESS=(HOST=$ORACLE_HOSTNAME)(PORT=$DB_PORT)(PROTOCOL=tcp))\" scope=both;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="shutdown immediate;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="startup mount;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database archivelog;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database open;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database flashback on;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="alter database force logging;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


cmd1="ALTER PLUGGABLE DATABASE ALL OPEN;"
# cmd=$(eval echo "$cmd1")
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$localconnectStr"


if [ ! -z "${ORACLE_PDB}" ]; then

setupShardPDB

fi

cmd1="create table shardsetup (status varchar2(10));"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$systemStr"


cmd1="insert into shardsetup values('completed');"
print_message "Sending query to sqlplus to execute $cmd1"
executeSQL  "$cmd1"   "$systemStr"

}

######################################################################## Primary Shard Setup ends here #################################

######################################################################## GSM Setup Task Begin here #####################################
setupGSM()
{
local cstatus='false'
local sstatus='false'

setupGSMCatalog
startGSM
addShardGroup
setupGSMShard

}

startGSM()
{

cmd1="start gsm"
print_message "Sending query to gsm to execute $cmd1"
executeGSM "$cmd1"
}

deployShard()
{

cmd1="deploy"
print_message "Sending query to gsm to execute $cmd1"
executeGSM "$cmd1"
}

stopGSM()
{

cmd1="stop gsm"
print_message "Sending query to gsm to execute $cmd1"
executeGSM "$cmd1"
}

addInvitedNode()
{

chost=$1

cmd1="add invitednode $chost"
print_message "Sending query to gsm to execute $cmd1"
executeGSM "$cmd1"
}


addShardGroup()
{

cmd1="add shardgroup -shardgroup ${shardGName} -deploy_as ${deployment_type} -region ${region}"
print_message "Sending query to gsm to execute $cmd1"
executeGSM "$cmd1"
}

checkStatus()
{
host=$1
port=1521
cpdb=$3
ccdb=$2
uname="system"
cpasswd=${ORACLE_PWD}

print_message "Connect String $uname/$cpasswd@//$host:$port/$ccdb"
output=$( "$ORACLE_HOME"/bin/sqlplus -s "$uname/$cpasswd@//$host:$port/$ccdb" <<EOF
       set heading off feedback off verify off echo off PAGESIZE 0
       select status from shardsetup;
       exit
EOF
)

 if [ "${output}" == 'completed' ];then
   print_message "Returned status from catalog is $output"
 else
   print_message "Sleeping for 300 seconds as returned status is not $output "
   sleep 300
 fi

 echo $output
}

setupGSMCatalog()
{
IFS='; ' read -r -a sarray   <<< "$CATALOG_PARAMS"
for element in "${sarray[@]}"
do
  print_message "1st String in Shard params $element"
  type=$( echo $element | awk -F: '{print $NF }')
    host=$( echo $element | awk -F: '{print $1 }')
    db=$( echo $element | awk -F: '{print $2 }')
    pdb=$( echo $element | awk -F: '{print $3 }')
done

print_message "Set variables to  host=${host} db=${db} pdb=${pdb}"
if [ ! -z "${host}" ] && [ ! -z "${db}" ] && [ ! -z "${pdb}" ]
then
runtime="60 minute"
endtime=$(date -ud "$runtime" +%s)

while [[ $(date -u +%s) -le $endtime ]]
do
    
    coutput=$( checkStatus $host $db $pdb )
    if [ "${coutput}" == 'completed' ] ;then
        configureGSMCatalog $host $db $pdb
        break
    else
       print_message "Catalog Status must return completed but returned value is $coutput"
    fi
  print_message "Catalog DB is still not ready. Sleeping for 60 seconds"
  sleep 60
done
fi

if [ "${coutput}" != 'completed' ] ;then
 error_exit "Shard Catalog is not setup, Unable to proceed futher"
fi

}

configureGSMCatalog()
{
chost=$1
cport=1521
cpdb=$3
ccdb=$2
gsmhost=${ORACLE_HOSTNAME}
cadmin=${SHARD_ADMIN_USER}
cpasswd=${ORACLE_PWD}
##########################
region="${REGION}"
shardGName="${SHARD_GROUP_NAME}"
deployment_type="${SHARD_DEPLOYMENT_TYPE}"
local gdsScript="/tmp/gdsScript.sql"

gsm_name="${SHARD_DIRECTOR_NAME}"
echo "create shardcatalog -database \"(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=${chost})(PORT=${cport}))(CONNECT_DATA=(SERVICE_NAME=${cpdb})))\" -user ${cadmin}/${cpasswd} -sdb shardcatalog -region region1,region2 -agent_port 8080 -agent_password ${cpasswd} -autovncr off" > "${gdsScript}"
echo "add invitednode ${chost}" >> "${gdsScript}"
echo "add gsm -gsm ${gsm_name}  -listener 1521 -pwd ${cpasswd} -catalog ${chost}:${cport}/${cpdb}  -region region1 -endpoint '(ADDRESS=(PROTOCOL=tcp)(HOST=${gsmhost})(PORT=1521))'" >> "${gdsScript}"
echo "exit" >> "${gdsScript}"
print_message "Sending script to gsm to execute ${gdsScript}"
cat ${gdsScript} >> $LOGFILE
cp "${gdsScript}" "${gdsScript}.test"
executeGSM "$cmd1" "gdsScript" "${gdsScript}"
}

setupGSMShard()
{
IFS='; ' read -r -a sarray   <<< "$PRIMARY_SHARD_PARAMS"
arrLen=$( echo "${#sarray[@]}" )
count1=0

runtime="45 minute"
endtime=$(date -ud "$runtime" +%s)

print_message "Set variables to  host=${host} db=${db} pdb=${pdb}"
while [[ $(date -u +%s) -le $endtime ]]
do
 for i in ${!sarray[@]}; do
      print_message "1st String in Shard params $element"
      host=$( echo ${sarray[i]}  | awk -F: '{print $1 }')
      db=$( echo ${sarray[i]} | awk -F: '{print $2 }')
      pdb=$( echo ${sarray[i]} | awk -F: '{print $3 }')
      print_message "shard env set to host=${host} db=${db} pdb=${pdb}"
      if [ ! -z "${host}" ] && [ ! -z "${db}" ] && [ ! -z "${pdb}" ]
      then
        coutput=$( checkStatus $host $db $pdb )
        if [ "${coutput}" == 'completed' ] ;then
           configureGSMShard $host $db $pdb
           unset sarray[i] 
           ((++count1))
       else
          print_message "Catalog Status must return completed but returned value is $coutput"
        fi 
      fi
 done
    if [ ${count1} -ge ${arrLen} ]; then
      break;
    fi
  print_message "Shards are still not ready. Sleeping for 120 seconds"
  sleep 120
done
}

configureGSMShard()
{
chost=$1
cport=1521
cpdb=$3
ccdb=$2
cpasswd=${ORACLE_PWD}
region=${REGION}
shardGName="${SHARD_GROUP_NAME}"
deployment_type="${SHARD_DEPLOYMENT_TYPE}"
local gdsScript="/tmp/gdsScript.sql"
admuser="${PDB_ADMIN_USER}"

echo "connect ${admuser}/${cpasswd}" > "${gdsScript}" 
echo "add cdb -connect ${chost}:${cport}:${ccdb} -pwd ${cpasswd}" >> "${gdsScript}"
echo "add shard -cdb ${ccdb} -connect ${chost}:${cport}/${cpdb} -shardgroup ${shardGName} -pwd ${cpasswd}" >> "${gdsScript}"
echo "config vncr" >> "${gdsScript}"
echo "sql 'update gsmadmin_internal.database set hostid=NULL '" >>  "${gdsScript}"
echo "exit" >> "${gdsScript}"
print_message "Sending script to gsm to execute ${gdsScript}"
cat ${gdsScript} >> $LOGFILE
executeGSM "$cmd1" "gdsScript" "${gdsScript}"
print_message " Calling Stop GSM function"
stopGSM
print_message "Stop GSM function completed, sleeping for 20 seconds"
sleep 20
print_message " Calling Start GSM function"
startGSM
print_message "Start GSM function completed, sleeping for 30 seconds"
sleep 30
print_message "Calling invitenode function to add the shard"
addInvitedNode $chost
deployShard
}

####################################################################### GSM Setup Task Ends here #########################################


######################################################################### Execute GSM Statements #########################################
executeGSM()
{
gsmQuery=$1
type=$2
gdsScript=$3

if [ -z "${gsmQuery}" ]; then
  print_message "Empty gdsQuery passed to gds"
fi

if [ -z "${type}" ]; then
   type='notSet'
fi

if [ -z "${gdsScript}" ]; then
   gdsScript='notSet'
fi

if  [ "${type}" == "gdsScript" ]; then
print_message "Executing gds script "
"$ORACLE_HOME"/bin/gdsctl @${gdsScript}
else
print_message "Executing GSM query"
"$ORACLE_HOME"/bin/gdsctl << EOF >> $LOGFILE
 $gsmQuery
 exit
EOF
fi
}
######################################################################## Execute GSM Statements Ends here ################################

########################################################################## Execute SQL Function Begin here ##############################
executeSQL()
{
sqlQuery=$1
connectStr=$2
type=$3
sqlScript=$4

if [ -z "${sqlQuery}" ]; then
  print_message "Empty sqlQuery passed to sqlplus. Operation Failed"
fi

if [ -z "${connectStr}" ]; then
   error_exit "Empty connectStr  passed to sqlplus. Operation Failed"
fi

if [ -z "${type}" ]; then
   type='notSet'
fi

if [ -z "${sqlScript}" ]; then
   sqlScript='notSet'
fi

if  [ "${type}" == "sqlScript" ] && [ -f ${sqlScript} ]; then
print_message "Executing sql script using connect string"
"$ORACLE_HOME"/bin/sqlplus -s "$connectStr" << EOF >> $LOGFILE
@ ${sqlScript}
EOF
else
print_message "Executing sqlQuery using connect string"
"$ORACLE_HOME"/bin/sqlplus -s "$connectStr" << EOF >> $LOGFILE
$sqlQuery
EOF
fi
}

############################################################################## Execute SQl Function ends here #################################

#######################################
################## MAIN ###############

if [ "${OP_TYPE}" == "primaryshard" ]; then
   print_message "Performing Checks before proceeding for setup"
   dbChecks
   print_message "OP_TYPE set to ${OP_TYPE}. Process to setup ${OP_TYPE} will begin now"
   resetPassword
   setupShardCDB
elif [ "${OP_TYPE}" == "standbyshard" ]; then
   print_message "Performing Checks before proceeding for setup"
   dbChecks
   print_message "OP_TYPE set to ${OP_TYPE}. Process to setup ${OP_TYPE} will begin now"
   setupShardStandby
elif [ "${OP_TYPE}" == "catalog" ]; then
  print_message "Performing Checks before proceeding for setup"
  dbChecks
  print_message "OP_TYPE set to ${OP_TYPE}. Process to setup ${OP_TYPE} will begin now"
  resetPassword
  setupCatalog
elif [ "${OP_TYPE}" == "gsm" ]; then
  print_message "Performing Checks before proceeding for setup"
  gsmChecks
  print_message "OP_TYPE set to ${OP_TYPE}. Process to setup ${OP_TYPE} will begin now"
  setupGSM
else
  print_message "OP_TYPE must be set to (gsm|catalog|primaryshard|standbyshard)"
  exit 15
fi
