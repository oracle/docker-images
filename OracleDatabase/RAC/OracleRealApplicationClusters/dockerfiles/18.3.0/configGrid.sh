#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Setup grid and Creates an Oracle Database based on following parameters:
#              $PUBLIC_HOSTNAME
#              $PUBLIC_IP
#              $ORACLE_SID
#              $ORACLE_PDB
# Note :
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

####################### Variables and Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -r GRID_USER='grid'          ## Default gris user is grid.
declare -r ORACLE_USER='oracle'      ## default oracle user is oracle.
declare -r ETCHOSTS="/etc/hosts"     ## /etc/hosts file location.
declare -r OSDBA='dba'                ## OSDBA group
declare -r OSASM='asmadmin'          ## OSASM group
declare -r INSTALL_TYPE='CRS_CONFIG' ## INSTALL TYPE default set to CRS_CONFIG
declare -r IPMI_FLAG='false'         ## IPMI Flag by default to set false
declare -r ASM_STORAGE_OPTION='ASM'  ## ASM_STORAGE_OPTION set to ASM
declare -r GIMR_ON_NAS='false'       ## GIMR on NAS set to false

declare -x ASM_DISKGROUP_DISKS       ## Computed during program Execution
declare -x ASM_DISKGROUP_FG_DISKS    ## Computing During program execution.
declare -x GIMR_DISKGROUP_DISKS      ## Computed During Program Execution
declare -x GIMR_DISKGROUP_FG_DISKS   ## Computed During program Execution.
declare -x GIMR_DEVICE_LIST          ## Pass as env variable and it must contain device name with location if using DSC. Default DG name is MGMT.
declare -x ASM_DEVICE_LIST           ## Pass as env variable and it must contain device name with location for DATA DG.
declare -x ETH_CARD_1                ## Computed During program Execution
declare -x ETH_CARD_2                ## Computed During Program Execution
declare -x PUBLIC_NETWORK            ## Computed During program execution.
declare -x PRIVATE_NETWORK           ## Computed During program execution.
declare -x NETWORK_STRING            ## Do not pass as env variable. Computed during program execution.
declare -x GIMR_DG_FLAG              ## Default set to FALSE. If under DSC, set to true.
declare -x GIMR_DG_NAME              ## Default set to MGMT.
declare -x GIMR_DG_REDUNDANCY        ## Used if you will use DSC. Default set to EXTERNAL.
declare -x DOMAIN                    ## Domain name will be computed based on hostname -d, otherwise pass it as env variable. 
declare -x PUBLIC_IP                 ## Computed based on Node name.  
declare -x PUBLIC_HOSTNAME           ## PUBLIC HOSTNAME set based on hostname
declare -x DHCP_CONF='false'         ## Pass env variable where value set to true for DHCP based installation.
declare -x NODE_VIP                  ## Pass it as env variable.
declare -x VIP_HOSTNAME              ## Pass as env variable.
declare -x SCAN_NAME                 ## Pass it as env variable.
declare -x SCAN_PORT                 ## Default SCAN_PORT set to 1521. Pass some other value if need some other PORT.
declare -x SCAN_IP                   ## Pass as env variable if you do not have DNS server. Otherwise, do not pass this variable.
declare -x SINGLENIC='false'         ## Default value is false as we should use 2 nics if possible for better performance.
declare -x PRIV_IP                   ## Pass PRIV_IP is not using SINGLE NIC   
declare -x CONFIGURE_GNS             ## Default value set to false. However, under DSC checks, it is reverted to true.
declare -x GNS_OPTIONS               ## By Default value will be CREATE_NEW_GNS
declare -x GNSVIP_HOSTNAME            ## If you are using DSC or DHCP for grid.
declare -x GNS_SUBDOMAIN             ## If you are using DHCP. 
declare -x COMMON_SCRIPTS            ## COMMON SCRIPT Locations. Pass this env variable if you have custom responsefile for grid and other scripts for DB.
declare -x PRIV_HOSTNAME             ## if SINGLENIC=true then PRIV and PUB hostname will be same. Otherise pass it as env variable.
declare -x CMAN_HOSTNAME             ## If you want to use connection manager to proxy the DB connections
declare -x CMAN_IP                   ## CMAN_IP if you want to use connection manager to proxy the DB connections
declare -x OS_PASSWORD               ## if not passed as env variable, it will be set to PASSWORD
declare -x GRID_PASSWORD             ## if not passed as env variable , it will be set to OS_PASSWORD
declare -x ORACLE_PASSWORD           ## if not passed as env variable, it will be set to OS_PASSWORD
declare -x PASSWORD                  ## If not passed as env variable , it will be set as system generated password
declare -x CLUSTER_NAME              ## if not passed as env variable. It will be set to "hostname-c".
declare -x CLUSTER_TYPE='STANDALONE'   ## Default instllation is STANDALONE. You can pass DOMAIn or MEMBERDB.
declare -x GRID_RESPONSE_FILE        ## IF you pass this env variable then user based responsefile will be used. default location is COMMON_SCRIPTS.
declare -x SCRIPT_ROOT               ## SCRIPT_ROOT will be set as per your COMMON_SCRIPTS.Do not Pass env variable SCRIPT_ROOT.
declare -x STORAGE_OPTIONS_FOR_MEMBERDB ##Pass it as env variable if you want to specify storage options for MEMBER DB Cluster.
declare -x DB_ASM_DISKGROUP='DATA'   ## Pass it env variable when using Member DB cluster. Default value is DATA. Another vakue can be MGMT.
declare -x MEMBERDB_FILE             ## Mandatory Parameter for MEMBER DB CLUSTER. Pass the Manifest file name. Copy it under COMMON_SCRIPTS.
declare -x ORACLE_CHARACTERSET       ## If not passed as env variable then default value is AL32UTF8.
declare -x ORACLE_PWD                ## If not passed as env variable then default value is set to PASSWORD  
declare -x ORACLE_PDB                ## If not passed then oraclepdb is default pdb name
declare -x ORACLE_SID                ## If not passed then default db name is oraclecdb.
declare -x CONTAINER_DB_FLAG='true'  ## default database will be created as container. Set it to false to create Non-CDB
declare -r OSOPER	             ## OSOPER group 		
declare -x IPMI_USERNAME             ## Specify IPMI Username
declare -x IPMI_PASSWORD             ## IPMI_PASSWORD 
declare -x ASM_REDUNDANCY='EXTERNAL' ## ASM REDUNDANCY default to EXTERNAL
declare -x SCAN_TYPE='LOCAL_SCAN'    ## SCAN TYPE set to LOCAL
declare -x SHARED_SCAN               ## SHARED_SCAN. define file for SHARED SCAN
declare -x EXTENDED_CLUSTER=false    ## EXTENDED CLUSTER DEFAULT set to false
declare -x SHARED_GNS_FILE           ## Specify SHARED GNS
declare -x EXTENDED_CLUSTER_SITES    ## Specify Extended Cluster Sites   
declare -x ASM_ON_NAS                ## Specify ASM on NAS
declare -x ASM_ON_NAS_LOCATION       ## Specify ASM on NAS Location
declare -x FAILURE_GROUP_SITE_NAME   ## Specify Failure Group Site Name
declare -x QUORUM_FAILURE_GROUP      ## Specify QUORUM Failure Group name
declare -x GIMR_DG_FAILURE_GROUP     ## Specufy DG Failure name
declare -x CONFIGURE_AFD_FLAG='false'  ##Specify Configure AFD Flag  
declare -x CONFIGURE_RHPS_FLAG='false' ## Speicfy Configure RHPS Flag
declare -x EXECUTE_ROOT_SCRIPT_FLAG='fasle'   ## Specify ROOT Script Flag
declare -x EXECUTE_ROOT_SCRIPT_METHOD='ROOT'  ## Specify Execute Root Script methid
declare -x IGNORE_CVU_CHECKS='true'           ## Ignore CVU Checks
declare -x SECRET_VOLUME='/run/secrets/'      ## Secret Volume
declare -x PWD_KEY='pwd.key'                  ## PWD Key File
declare -x ORACLE_PWD_FILE
declare -x GRID_PWD_FILE
declare -x REMOVE_OS_PWD_FILES='false'
declare -x DB_PWD_FILE
declare -x COMMON_OS_PWD_FILE='common_os_pwdfile.enc'
declare -x CRS_NODES
declare -x CRS_CONFIG_NODES
declare -x ANSIBLE_INSTALL='false'

progname=$(basename "$0")
###################### Variabes and Constants declaration ends here  ####################


############Sourcing Env file##########
if [ -f "/etc/rac_env_vars" ]; then
source "/etc/rac_env_vars"
fi
##########Source ENV file ends here####


###################Capture Process id and source functions.sh###############
source "$SCRIPT_DIR/functions.sh"
###########################sourcing of functions.sh ends here##############

####error_exit function sends a TERM signal, which is caught by trap command and returns exit status 15"####
trap '{ exit 15; }' TERM
###########################trap code ends here##########################


####### all_check function to validate all the required variable before proceeding for the installation #######

all_check()
{
check_pub_host_name
check_ip_env_vars
check_passwd_env_vars
check_dsc_env_vars
check_dhcp_env_vars
check_rspfile_env_vars
check_db_env_vars
}

############## Public Hostname, IP and Domain begin here ##############

check_pub_host_name()
{
local domain_name
local stat

if [ -z "${PUBLIC_IP}" ]; then
    PUBLIC_IP=$(dig +short "$(hostname).$DOMAIN")
    print_message "Public IP is set to ${PUBLIC_IP}"
else
    print_message "Public IP is set to ${PUBLIC_IP}"
fi

if [ -z "${PUBLIC_HOSTNAME}" ]; then
  PUBLIC_HOSTNAME=$(hostname)
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
 else
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
fi

if [ -z "${DOMAIN}" ]; then
domain_name=$(hostname -d)
 if [ -z "${domain_name}" ];then
   print_message  "Domain name is not defined. Setting Domain to 'example.com'"
    DOMAIN="example.com"
 else
    DOMAIN=${domain_name}
fi
 else
 print_message "Domain is defined to $DOMAIN"
fi


}

############## Public Hostname, IP and Domain end here ##############

############## IP Related Checks Begins   here ##############
check_ip_env_vars ()
{
local domain_name

if [ "${DHCP_CONF}" != 'true' ]; then
  print_message "Default setting of AUTO GNS VIP set to false. If you want to use AUTO GNS VIP, please pass DHCP_CONF as an env parameter set to true"
  DHCP_CONF=false
if [ ${ANSIBLE_INSTALL} == 'false' ]; then

if [ -z "${NODE_VIP}" ]; then
   error_exit "RAC Node ViP is set to empty string"
else
   print_message "RAC VIP set to ${NODE_VIP}"
fi

if [ -z "${VIP_HOSTNAME}" ]; then
   error_exit "RAC Node Vip hostname is set to empty string"
else
   print_message "RAC Node VIP hostname is set to ${VIP_HOSTNAME} "
fi
fi


if [ -z "${SCAN_NAME}" ]; then
  error_exit "SCAN_NAME set to the empty string"
else
  print_message "SCAN_NAME name is ${SCAN_NAME}"
fi

if [ -z "${SCAN_PORT}" ]; then
 print_message "SCAN PORT is set to empty string. Setting it to 1521 port."
  SCAN_PORT=1521
else
  print_message "SCAN_PORT name is ${SCAN_PORT}"
fi

if resolveip "${SCAN_NAME}"; then
 print_message "SCAN Name resolving to IP. Check Passed!"
else
  error_exit "SCAN Name not resolving to IP. Check Failed!"
fi

if [ -z "${SCAN_IP}" ]; then
   print_message "SCAN_IP set to the empty string"
else
  print_message "SCAN_IP name is ${SCAN_IP}"
fi
### DHCP Check ENDS Here ######
fi

if [ "${SINGLENIC}" == 'true' ];then
PRIV_IP=${PUBLIC_IP}
PRIV_HOSTNAME=${PUBLIC_HOSTNAME}
fi

if [ ${ANSIBLE_INSTALL} == 'false' ]; then

if [ -z "${PRIV_IP}" ]; then
   error_exit "RAC Node private ip is  set to empty string"
else
   print_message "RAC Node PRIV IP is set to ${PRIV_IP} "
fi

if [ -z "${PRIV_HOSTNAME}" ]; then
   error_exit "RAC Node private hostname set  to empty string"
else
  print_message "RAC Node private hostname is set to ${PRIV_HOSTNAME}"
fi

fi

if [ -z "${CMAN_HOSTNAME}" ]; then
  print_message  "CMAN_NAME set to the empty string"
else
  print_message "CMAN_HOSTNAME name is ${CMAN_HOSTNAME}"
fi

if [ -z "${CMAN_IP}" ]; then
   print_message "CMAN_IP set to the empty string"
else
  print_message "CMAN_IP name is ${CMAN_IP}"
fi

if [ -z "${CLUSTER_NAME}" ]; then
   print_message "Cluster Name is not defined"
   print_message "Cluster name is set to 'racnode-c'"
   CLUSTER_NAME="$(hostname)-c"
else
  print_message "Cluset name is set to $CLUSTER_NAME"
fi

}

############## IP Related Checks end here ##############

############## Checks for password brgins here  #########
check_passwd_env_vars ()
{

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
 PASSWORD=O$(openssl rand -base64 6 | tr -d "=+/")_1
fi

if [ ! -z "${GRID_PWD_FILE}" ]; then
cmd='openssl enc -d -aes-256-cbc -in "${SECRET_VOLUME}/${GRID_PWD_FILE}" -out "/tmp/${GRID_PWD_FILE}" -pass file:"${SECRET_VOLUME}/${PWD_KEY}"'

eval $cmd 

if [ $? -eq 0 ]; then
print_message "Password file generated"
else
error_exit "Error occurred during Grid password file generation"
fi

read GRID_PASSWORD < /tmp/${GRID_PWD_FILE}
rm -f /tmp/${GRID_PWD_FILE}
else
  GRID_PASSWORD="${PASSWORD}"
  print_message "Common OS Password string is set for Grid user"
fi

if [ ! -z "${ORACLE_PWD_FILE}" ]; then
cmd='openssl enc -d -aes-256-cbc -in "${SECRET_VOLUME}/${ORACLE_PWD_FILE}" -out "/tmp/${ORACLE_PWD_FILE}" -pass file:"${SECRET_VOLUME}/${PWD_KEY}"'

eval $cmd


if [ $? -eq 0 ]; then
print_message "Password file generated"
else
error_exit "Error occurred during Oracle  password file generation"
fi

read ORACLE_PASSWORD < /tmp/${ORACLE_PWD_FILE}
rm -f /tmp/${GRID_PWD_FILE}
else
  ORACLE_PASSWORD="${PASSWORD}"
  print_message "Common OS Password string is set for  Oracle user"
fi

if [ ! -z "${DB_PWD_FILE}" ]; then
cmd='openssl enc -d -aes-256-cbc -in "${SECRET_VOLUME}/${DB_PWD_FILE}" -out "/tmp/${DB_PWD_FILE}" -pass file:"${SECRET_VOLUME}/${PWD_KEY}"'

eval $cmd

if [ $? -eq 0 ]; then
print_message "Password file generated"
else
error_exit "Error occurred during common database password file generation"
fi

read ORACLE_PWD < /tmp/${DB_PWD_FILE}
rm -f /tmp/${DB_PWD_FILE}
else
   ORACLE_PWD="${PASSWORD}"
  print_message "Common OS Password string is set for Oracle Database"
fi


if [ "${REMOVE_OS_PWD_FILES}" == 'true' ]; then
rm -f  ${SECRET_VOLUME}/${COMMON_OS_PWD_FILE}
rm -f ${SECRET_VOLUME}/${PWD_KEY}
fi
}

############ Checks for password ends here################

############## Checks for Domain Service Cluster #########
check_dsc_env_vars ()
{
if [ "${CLUSTER_TYPE}" == "DOMAIN" ]; then
         print_message "Setting GIMR_DG_FLAG to TRUE"
           GIMR_DG_FLAG="true"
         print_message "Setting GIMR_DG_NAME to MGMT"
           GIMR_DG_NAME="MGMT"
         print_message "Setting GIMR_DG_REDUNDANCY to External"
           GIMR_DG_REDUNDANCY="EXTERNAL"
         print_message "Setting Configure GNS options to true"
           CONFIGURE_GNS=true
        if [ -z "${GNSVIP_HOSTNAME}" ]; then
           error_exit "GNS IP is not set or set to empty string"
        else
           print_message "GNS IP is set to ${GNSVIP_HOSTNAME} "
        fi

        if [ -z "${GNS_OPTIONS}" ]; then
           print_message "GNS OPTIONS set to empty string. Setting GNS OPTIONS to CREATE_NEW_GNS"
           GNS_OPTIONS="CREATE_NEW_GNS"
        else
           print_message "GNS OPTIONS is set to ${GNS_OPTIONS} "
        fi
else
      print_message "Setting CONFIGURE_GNS to false"
        CONFIGURE_GNS='false'
fi
}
############## Checks for DSC ends here ####################################################

############## Checks for DHCP Begin here ########################################
check_dhcp_env_vars ()
{
if [ "${DHCP_CONF}" == 'true' ];then

        if [ -z "${GNS_SUBDOMAIN}" ]; then
           error_exit "GNS_SUBDOMAIN is not set or set to empty string"
        else
           print_message "GNS SUBDOMAIN is set to ${GNS_SUBDOMAIN} "
        fi

        if [ -z "${GNSVIP_HOSTNAME}" ]; then
           error_exit "GNS IP is not set or set to empty string"
        else
           print_message "GNS IP is set to ${GNSVIP_HOSTNAME} "
        fi

        if [ -z "${GNS_OPTIONS}" ]; then
           print_message "GNS OPTIONS set to empty string. Setting GNS OPTIONS to CREATE_NEW_GNS"
           GNS_OPTIONS="CREATE_NEW_GNS"
        else
           print_message "GNS OPTIONS is set to ${GNS_OPTIONS} "
        fi

fi
}

############# Checks for DHCP Ends here ###########################################

############### Check for Existing Grid Response file based on user settings begin here########

check_rspfile_env_vars ()
{
if [ -z "${GRID_RESPONSE_FILE}" ];then
print_message "GRID_RESPONSE_FILE env variable set to empty. $progname will use standard cluster responsefile"
else
if [ -f "${COMMON_SCRIPTS}/${GRID_RESPONSE_FILE}" ];then
cp "$COMMON_SCRIPTS/$GRID_RESPONSE_FILE" "$logdir/$GRID_INSTALL_RSP"
else
error_exit "$COMMON_SCRIPTS/$GRID_RESPONSE_FILE does not exist"
fi
fi

if [ -z "${SCRIPT_ROOT}" ]; then
SCRIPT_ROOT=$COMMON_SCRIPTS
print_message "Location for User script SCRIPT_ROOT set to $COMMON_SCRIPTS"
else
print_message "Location for User script SCRIPT_ROOT set to $SCRIPT_ROOT"
fi

print_message "IGNORE_CVU_CHECKS is set to ${IGNORE_CVU_CHECKS}"

}

############### Check for Existing Grid Response file based on user settings end here########

############## Check for Member Cluster and DB related parameters Begin here ##########################
check_db_env_vars ()
{
if [ "${CLUSTER_TYPE}" == 'MEMBERDB' ]; then
print_message "Checking StorageOption for MEMBERDB Cluster"

if [ -z "${STORAGE_OPTIONS_FOR_MEMBERDB}" ]; then
print_message "Storage Options is set to CLIENT_ASM_STORAGE"
         STORAGE_OPTIONS_FOR_MEMBERDB=CLIENT_ASM_STORAGE
else
print_message "Storage Options is set to STORAGE_OPTIONS_FOR_MEMBERDB"
fi

if [ -z "${MEMBERDB_FILE}" ];then
  error_exit "Manifest File is not provided for MEMBERDB cluster. Exiting.."
else
 print_message "Manifest File is set to $MEMBERDB_FILE"
	if [ -f "${COMMON_SCRIPTS}"/"${MEMBERDB_FILE}" ]; then
	   print_message "Manifest File exist at ${COMMON_SCRIPTS}/${MEMBERDB_FILE}"
	else
	   error_exit "Manifest File exist at ${COMMON_SCRIPTS}/${MEMBERDB_FILE}. Check Failed!"
	fi
fi

if [ -z "${DB_ASM_DISKGROUP}" ];then
print_message "ASM Diskgroup name for MemberDB is set to $DB_ASM_DISKGROUP"
else
print_message "ASM Diskgroup name for MemberDB is set to $DB_ASM_DISKGROUP"
fi

fi

############## Following Checks are applicable only if CLUSTER TYPE is STANDALONE#########

if [ $CLUSTER_TYPE == 'STANDALONE' ] || [ $CLUSTER_TYPE == 'MEMBERDB' ]; then
if [ -z "${ORACLE_SID}" ]; then
export ORACLE_SID="ORCLCDB"
print_message "Oracle SID is set to $ORACLE_SID"
else
print_message "Oracle SID is set to $ORACLE_SID"
fi

if [ -z "${ORACLE_PDB}" ]; then
export ORACLE_PDB="ORCLPDB"
print_message "Oracle PDB name is set to $ORACLE_PDB"
else
print_message "Oracle PDB name is set to $ORACLE_PDB"
fi

if [ -z "${ORACLE_CHARACTERSET}" ]; then
export ORACLE_CHARACTERSET="AL32UTF8"
else
print_message "DB characterset set to $ORACLE_CHARACTERSET"
fi
fi
}

############## Check for Member Cluster Begin here ########################
################ all_check function related tasks ends here #################


########################################### SSH Function begin here ########################
setupSSH()
{
local CLUSTER_NODES
if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  CLUSTER_NODES=$( echo $CRS_NODES | tr ',' ' ' ) 
fi

print_message "SSh will be setup among $CLUSTER_NODES nodes"

print_message "Running SSH setup for $GRID_USER user between nodes $CLUSTER_NODES"
cmd='su - $GRID_USER -c "$EXPECT $SCRIPT_DIR/$SETUPSSH $GRID_USER \"$GRID_HOME/oui/prov/resources/scripts\"  \"$CLUSTER_NODES\" \"$GRID_PASSWORD\""'
eval $cmd
sleep 30
print_message "Running SSH setup for $ORACLE_USER user between nodes $CLUSTER_NODES"
cmd='su - $ORACLE_USER -c "$EXPECT $SCRIPT_DIR/$SETUPSSH $ORACLE_USER \"$DB_HOME/oui/prov/resources/scripts\"  \"$CLUSTER_NODES\" \"$ORACLE_PASSWORD\""'
eval $cmd
}

checkSSH ()
{

local password
local ssh_pid
local stat
local status
local CLUSTER_NODES

if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  CLUSTER_NODES=$( echo $CRS_NODES | tr ',' ' ' )
fi

cmd='su - $GRID_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $GRID_USER@$node echo ok 2>&1"'
echo $cmd

for node in ${CLUSTER_NODES}
do

status=$(eval $cmd)

if [[ $status == ok ]] ; then
  print_message "SSH check fine for the $node"

elif [[ $status == "Permission denied"* ]] ; then
   error_exit "SSH check failed for the $GRID_USER@$node beuase of permission denied error! SSH setup did not complete sucessfully"
else
   error_exit "SSH check failed for the $GRID_USER@$node! Error occurred during SSH setup"
fi

done

status="NA"
cmd='su - $ORACLE_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $ORACLE_USER@$node echo ok 2>&1"'
 echo $cmd
for node in ${CLUSTER_NODES}
do

status=$(eval $cmd)

if [[ $status == ok ]] ; then
  print_message "SSH check fine for the $ORACLE_USER@$node"
elif [[ $status == "Permission denied"* ]] ; then
   error_exit "SSH check failed for the $ORACLE_USER@$node becuase of permission denied error! SSH setup did not complete sucessfully"
else
   error_exit "SSH check failed for the $ORACLE_USER@$node! Error occurred during SSH setup"
fi

done

}

######################################## SSH Function end here #############################

######################################### ASM Disk Functions ###################################
build_block_device_list ()
{
local stat
local count=1
local temp_str
local asmvol=$ASM_DISCOVERY_DIR
local asmdisk
local disk
local minsize=50
local size=0
local cluster_name="oracle"
local disk_name

if [ -z "${GRID_RESPONSE_FILE}" ]; then

if [ ! -z "${ASM_DEVICE_LIST}" ];then

print_message "Preapring Device list"
IFS=', ' read -r -a devices <<< "$ASM_DEVICE_LIST"
        local arr_device=${#devices[@]}
if [ $arr_device -ne 0 ]; then
        for device in "${devices[@]}"
        do
        ASM_DISKGROUP_FG_DISKS+="$device,,"
        ASM_DISKGROUP_DISKS+="$device,"
  #      ((size+=$(blockdev --getsize64 $device)))
  #      print_message "Disks size (bytes) : $size"
        print_message "Changing Disk permission and ownership"
        chown $GRID_USER:asmadmin $device
        chmod 660 $device
        count=$[$count+1]
       done
fi
size=$(echo "$size" | awk '{byte =$1 /1024/1024**2 ; print byte}')
print_message "ASM Disk size : $size"
else
error_exit "ASM_DEVICE_LIST is set to empty canot proceed"
fi

temp_str=$(echo -n $ASM_DISKGROUP_FG_DISKS | head -c -1)
export ASM_DISKGROUP_FG_DISKS=$temp_str
print_message "ASM Device list will be with failure groups $ASM_DISKGROUP_FG_DISKS"
temp_str=$(echo -n $ASM_DISKGROUP_DISKS | head -c -1)
export ASM_DISKGROUP_DISKS=$temp_str
print_message "ASM Device list will be groups $ASM_DISKGROUP_DISKS"
else
print_message "GRID_RESPONSE_FILE is set to ${GRID_RESPONSE_FILE}, so ASM_DEVICE_LIST env variable will be ignored"
fi
}

######################################### ASM Disk Functions ####################################

######################################### GIMR DEVICE Block Device List Computation Begin here #####
build_gimr_block_device_list ()
{
local stat
local count=1
local temp_str
local asmvol=$ASM_DISCOVERY_DIR
local asmdisk
local disk
local minsize=50
local size=0
local cluster_name="oracle"
local disk_name

if [ -z "${GRID_RESPONSE_FILE}" ]; then
if [ "${CLUSTER_TYPE}" == "DOMAIN" ]; then
if [ ! -z "${GIMR_DEVICE_LIST}" ];then

print_message "Preapring Device list"
IFS=', ' read -r -a devices <<< "$GIMR_DEVICE_LIST"
        local arr_device=${#devices[@]}
if [ $arr_device -ne 0 ]; then
        for device in "${devices[@]}"
        do
        GIMR_DISKGROUP_FG_DISKS+="$device,,"
        GIMR_DISKGROUP_DISKS+="$device,"
 #       ((size+=$(blockdev --getsize64 $device)))
 #       print_message "Disks size (bytes) : $size"
        print_message "Changing Disk permission and ownership"
        chown $GRID_USER:asmadmin $device
        chmod 660 $device
        count=$[$count+1]
       done
fi
size=$(echo "$size" | awk '{byte =$1 /1024/1024**2 ; print byte}')
print_message "ASM Disk size : $size"
else
error_exit "GIMR_DEVICE_LIST is set to empty cannot proceed"
fi

temp_str=$(echo -n $GIMR_DISKGROUP_FG_DISKS | head -c -1)
export GIMR_DISKGROUP_FG_DISKS=$temp_str
print_message "GIMR Device list will be with failure groups $GIMR_DISKGROUP_FG_DISKS"
temp_str=$(echo -n $GIMR_DISKGROUP_DISKS | head -c -1)
export GIMR_DISKGROUP_DISKS=$temp_str
print_message "GIMR Device list will be set to  $GIMR_DISKGROUP_DISKS"
else
print_message "CLUSTER_TYPE env variable is set to ${CLUSTER_TYPE}, will not process GIMR DEVICE list as default Diskgroup is set to DATA. GIMR DEVICE List will be processed when CLUSTER_TYPE is set to DOMAIN for DSC"
fi
else
print_message "GRID_RESPONSE_FILE is set to ${GRID_RESPONSE_FILE}, so GIMR_DEVICE_LIST env variable will be ignored"
fi
}

######################################### GIMR Block Device List Computation ends here ############

######################################## Set Device Permissions on all the nodes #######################
setDevicePermissions ()
{

local cmd
local state=3

if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  IFS=', ' read -r -a CLUSTER_NODES <<< "$CRS_NODES"
fi

print_message "Nodes in the cluster ${CLUSTER_NODES[@]}"
for node in "${CLUSTER_NODES[@]}"; do
print_message "Setting Device permissions for RAC Install  on $node"

if [ ! -z "${GIMR_DEVICE_LIST}" ];then

print_message "Preapring GIMR Device list"
IFS=', ' read -r -a devices <<< "$GIMR_DEVICE_LIST"
        local arr_device=${#devices[@]}
if [ $arr_device -ne 0 ]; then
        for device in "${devices[@]}"
        do
        print_message "Changing Disk permission and ownership"
        cmd='su - $GRID_USER -c "ssh $node sudo chown $GRID_USER:asmadmin $device"'
        print_message "Command : $cmd execute on $node"
        eval $cmd
        unset cmd
        cmd='su - $GRID_USER -c "ssh $node sudo chmod 660 $device"'
        print_message "Command : $cmd execute on $node"
        eval $cmd
        unset cmd
        print_message "Populate Rac Env Vars on Remote Hosts"
        cmd='su - $GRID_USER -c "ssh $node sudo echo export GIMR_DEVICE_LIST=${GIMR_DEVICE_LIST} >> $RAC_ENV_FILE"' 
       done
fi

if [ ! -z "${ASM_DEVICE_LIST}" ];then

print_message "Preapring ASM Device list"
IFS=', ' read -r -a devices <<< "$ASM_DEVICE_LIST"
        local arr_device=${#devices[@]}
if [ $arr_device -ne 0 ]; then
        for device in "${devices[@]}"
        do
        print_message "Changing Disk permission and ownership"
        cmd='su - $GRID_USER -c "ssh $node sudo chown $GRID_USER:asmadmin $device"'
        print_message "Command : $cmd execute on $node"
        eval $cmd
        unset cmd
        cmd='su - $GRID_USER -c "ssh $node sudo chmod 660 $device"'
        print_message "Command : $cmd execute on $node"
        eval $cmd
        unset cmd
        print_message "Populate Rac Env Vars on Remote Hosts"
        cmd='su - $GRID_USER -c "ssh $node sudo echo export ASM_DEVICE_LIST=${ASM_DEVICE_LIST} >> $RAC_ENV_FILE"'
       done
fi


done

}

######################################## Set Device Permission Ends Here ################################

####################################### Network Function Begin here #############################
build_network ()
{

if [ -z "${GRID_RESPONSE_FILE}" ]; then

####### Building Public IP Details ###########
ETH_CARD_2=$(ifconfig | awk "/${PUBLIC_IP}/ {print $1}"  RS="\n\n" | awk -F ":" '{ print $1 }' | head -1)

if check_interface $ETH_CARD_2 ; then
  print_message "Check passed for network card $ETH_CARD_2 for public IP $PUBLIC_IP"
 else
 error_exit "Check failed for network card for $ETH_CARD_2 for public IP $PUBLIC_IP"
 fi

PUBLIC_NETMASK=$(ifconfig $ETH_CARD_2  | awk '/netmask/ {print $4}')
print_message "Public Netmask : $PUBLIC_NETMASK"
PUBLIC_NETWORK=$(ipcalc -np $PUBLIC_IP $PUBLIC_NETMASK | grep NETWORK | awk -F '=' '{ print $2 }')

##### Building Private Network Detail #########

ETH_CARD_1=$(ifconfig | awk "/${PRIV_IP}/ {print $1}" RS="\n\n" | awk -F ":" '{ print $1 }' | head -1)

if check_interface $ETH_CARD_1 ; then
  print_message "Check passed for network card $ETH_CARD_1 for private IP $PRIV_IP"
else
 error_exit "Check failed for network card for $ETH_CARD_1 for private IP $PRIV_IP"
fi

PRIVATE_NETMASK=$(ifconfig $ETH_CARD_1  | awk '/netmask/ {print $4}')
PRIVATE_NETWORK=$(ipcalc -np $PRIV_IP $PRIVATE_NETMASK | grep NETWORK | awk -F '=' '{ print $2 }')

print_message "Building NETWORK_STRING to set  networkInterfaceList in Grid Response File"

if [ "${SINGLENIC}" == "true" ]; then
NETWORK_STRING="$ETH_CARD_1:$PUBLIC_NETWORK:1"
else
NETWORK_STRING="$ETH_CARD_2:$PUBLIC_NETWORK:1,$ETH_CARD_1:$PRIVATE_NETWORK:5"
fi

print_message "Network InterfaceList  set to $NETWORK_STRING"
else
print_message "GRID_RESPONSE_FILE is set to ${GRID_RESPONSE_FILE}, so ASM_DEVICE_LIST env variable will be ignored"
fi

}

########################################## Network Function End here ################################

######### Grid setup Function###########################
grid_response_file ()
{

if [ -z $GRID_RESPONSE_FILE ]; then
cp $SCRIPT_DIR/$GRID_INSTALL_RSP $logdir/$GRID_INSTALL_RSP
#chmod 777 $logdir

if [ -z CRS_CONFIG_NODES ]; then
   CRS_CONFIG_NODES="$PUBLIC_HOSTNAME:$VIP_HOSTNAME:HUB"
fi

sed -i -e "s|###INVENTORY###|$INVENTORY|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CLUSTER_NAME###|$CLUSTER_NAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GRID_BASE###|$GRID_BASE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###SCAN_NAME###|$SCAN_NAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###HOSTNAME###|$PUBLIC_HOSTNAME|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###HOSTNAME_VIP###|$VIP_HOSTNAME|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###NETWORK_STRING###|$NETWORK_STRING|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_DISKGROUP_FG_DISKS###|$ASM_DISKGROUP_FG_DISKS|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_DISKGROUP_DISKS###|$ASM_DISKGROUP_DISKS|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_DISCOVERY_STRING###|$ASM_DISCOVERY_DIR/*|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###PASSWORD###|$ORACLE_PWD|g"  $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###STORAGE_OPTIONS_FOR_MEMBERDB###|$STORAGE_OPTIONS_FOR_MEMBERDB|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###SCAN_PORT###|$SCAN_PORT|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CLUSTER_TYPE###|$CLUSTER_TYPE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_DG_REDUNDANCY###|$GIMR_DG_REDUNDANCY|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_DISKGROUP_FG_DISKS###|$GIMR_DISKGROUP_FG_DISKS|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_DISKGROUP_DISKS###|$GIMR_DISKGROUP_DISKS|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_DG_FLAG###|$GIMR_DG_FLAG|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###NETWORK_STRING###|$NETWORK_STRING|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_DG_NAME###|$GIMR_DG_NAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GNS_SUBDOMAIN###|$GNS_SUBDOMAIN|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GNSVIP_HOSTNAME###|$GNSVIP_HOSTNAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GNS_OPTIONS###|$GNS_OPTIONS|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###DHCP_CONF###|$DHCP_CONF|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CONFIGURE_GNS###|$CONFIGURE_GNS|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###MEMBERDB_FILE###|$COMMON_SCRIPTS\/$MEMBERDB_FILE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###DB_ASM_DISKGROUP###|$DB_ASM_DISKGROUP|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###INSTALL_TYPE###|$INSTALL_TYPE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###OSDBA###|$OSDBA|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###OSOPER###|$OSOPER|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###OSASM###|$OSASM|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###SCAN_TYPE###|$SCAN_TYPE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###SHARED_SCAN_FILE###|$SHARED_SCAN_FILE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###EXTENDED_CLUSTER###|$EXTENDED_CLUSTER|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###SHARED_GNS_FILE###|$SHARED_GNS_FILE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###EXTENDED_CLUSTER_SITES###|$EXTENDED_CLUSTER_SITES|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###IPMI_FLAG###|$IPMI_FLAG|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###IPMI_USERNAME###|$IPMI_USERNAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###IPMI_PASSWORD###|$IPMI_PASSWORD|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_STORAGE_OPTION###|$ASM_STORAGE_OPTION|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_ON_NAS###|$ASM_ON_NAS|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_ON_NAS###|$GIMR_ON_NAS|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_ON_NAS_LOCATION###|$ASM_ON_NAS_LOCATION|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###ASM_REDUNDACNY###|$ASM_REDUNDANCY|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###AU_SIZE###|$AU_SIZE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###FAILURE_GROUP_SITE_NAME###|$FAILURE_GROUP_SITE_NAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###QUORUM_FAILURE_GROUP###|$QUORUM_FAILURE_GROUP|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GIMR_DG_FAILURE_GROUP###|$GIMR_DG_FAILURE_GROUP|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CONFIGURE_AFD_FLAG###|$CONFIGURE_AFD_FLAG|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CONFIGURE_RHPS_FLAG###|$CONFIGURE_RHPS_FLAG|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###EXECUTE_ROOT_SCRIPT_FLAG###|$EXECUTE_ROOT_SCRIPT_FLAG|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###EXECUTE_ROOT_SCRIPT_METHOD###|$EXECUTE_ROOT_SCRIPT_METHOD|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CRS_CONFIG_NODES###|$CRS_CONFIG_NODES|g" $logdir/$GRID_INSTALL_RSP
fi

}

cluvfy_checks ()
{
local responsefile=$logdir/$GRID_INSTALL_RSP
local password=$PASSWORD
local stat=3
local cmd
local FAILED_CMDS
local TIMESTAMP=$(date +%s)

if [ -f "$logdir/cluvfy_check.txt" ]; then
print_message "Moving any exisiting cluvfy $logdir/cluvfy_check.txt to $logdir/cluvfy_check_$TIMESTAMP.txt"
mv $logdir/cluvfy_check.txt $logdir/cluvfy_check."$(date +%Y%m%d-%H%M%S)".txt
fi

print_message "Performing Cluvfy Checks"
cmd='su - $GRID_USER -c "$GRID_HOME/runcluvfy.sh stage -pre crsinst -responseFile $responsefile | tee -a  $logdir/cluvfy_check.txt"'
eval $cmd

print_message "Checking $logdir/cluvfy_check.txt if there is any failed check."
FAILED_CMDS=$(sed -n -f - $logdir/cluvfy_check.txt << EOF
 /.*FAILED.*/ {
p
}
EOF
)

cat $logdir/cluvfy_check.txt > $STD_OUT_FILE

if [[ ${IGNORE_CVU_CHECKS} == 'true' ]]; then
print_message "CVU Checks are ignored as IGNORE_CVU_CHECKS set to true. It is recommended to set IGNORE_CVU_CHECKS to false and meet all the cvu checks requirement. RAC installation might fail, if there are failed cvu checks."
else
if [[ $FAILED_CMDS =~ .*FAILED*. ]] 
then
print_message "cluvfy failed for following  \n $FAILED_CMDS"
error_exit "Pre Checks failed for Grid installation, please check $logdir/cluvfy_check.txt"
fi
fi
}

RunConfigGrid()
{
local responsefile=$logdir/$GRID_INSTALL_RSP
local password=$PASSWORD
local stat=3
local cmd

if [ "${SINGLENIC}" == 'true' ];then
 error_exit  "SINGLE NIC is not supported";
else
cmd='su - $GRID_USER -c "$GRID_HOME/gridSetup.sh -waitforcompletion -ignorePrereq  -silent -responseFile $responsefile"'
eval $cmd
fi
}

runrootsh ()
{
local cmd
local state=3

if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  IFS=', ' read -r -a CLUSTER_NODES <<< "$CRS_NODES"
fi

print_message "Nodes in the cluster ${CLUSTER_NODES[@]}" 
for node in "${CLUSTER_NODES[@]}"; do
print_message "Running root.sh on $node"
cmd='su - $GRID_USER -c "ssh $node sudo $GRID_HOME/root.sh"'
eval $cmd
done
}

runpostrootsetps ()
{
local responsefile=$logdir/$GRID_INSTALL_RSP
local password=$PASSWORD
local stat=3
local cmd

print_message "Running post root.sh steps to setup Grid env"

cmd='su - $GRID_USER -c "$GRID_HOME/gridSetup.sh -executeConfigTools -responseFile $responsefile -silent"'
eval $cmd

#rm -f $responsefile
}

checkCluster ()
{
local cmd;
local stat;
local oracle_home=$GRID_HOME

IFS=', ' read -r -a CLUSTER_NODES <<< "$CRS_NODES"

print_message "Nodes in the cluster ${CLUSTER_NODES[@]}"


for node in "${CLUSTER_NODES[@]}"; do

print_message "Checking Cluster on $node"

cmd='su - $GRID_USER -c "ssh $node $GRID_HOME/bin/crsctl check crs"'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check passed"
else
error_exit "Cluster Check failed"
fi

cmd='su - $GRID_USER -c "ssh $node $GRID_HOME/bin/crsctl check cluster"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi


cmd='su - $GRID_USER -c "ssh $node $GRID_HOME/bin/srvctl status mgmtdb"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "MGMTDB Check went fine"
else
error_exit "MGMTDB Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node $GRID_HOME/bin/crsctl check crsd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node $GRID_HOME/bin/crsctl check cssd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node $GRID_HOME/bin/crsctl check evmd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

done

print_message "Removing $logdir/cluvfy_check.txt as cluster check has passed"
rm -f $logdir/cluvfy_check.txt

}

#############DB Setup Functions########################################

dbca_response_file ()
{

if [ -z $DBCA_RESPONSE_FILE ]; then
cp $SCRIPT_DIR/$DBCA_RSP $logdir/$DBCA_RSP
chmod 666 $logdir/$DBCA_RSP

if [ -z $CRS_NODES ]; then
  CRS_NODES=$PUBLIC_HOSTNAME
fi

sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $logdir/$DBCA_RSP
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $logdir/$DBCA_RSP
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $logdir/$DBCA_RSP
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" $logdir/$DBCA_RSP
sed -i -e "s|###PUBLIC_HOSTNAME###|$CRS_NODES|g" $logdir/$DBCA_RSP
sed -i -e "s|###DB_BASE###|$DB_BASE|g" $logdir/$DBCA_RSP
sed -i -e "s|###DB_HOME###|$DB_HOME|g" $logdir/$DBCA_RSP
sed -i -e "s|###CONTAINER_DB_FLAG###|$CONTAINER_DB_FLAG|g" $logdir/$DBCA_RSP
else

if [ -f $COMMON_SCRIPTS/$DBCA_RESPONSE_FILE ];then
cp $COMMON_SCRIPTS/$DBCA_RESPONSE_FILE $logdir/$DBCA_RSP
else
error_exit "$COMMON_SCRIPTS/$DBCA_RESPONSE_FILE does not exist"
fi

fi
}

createRACDB()
{
local responsefile=$logdir/$DBCA_RSP
local cmd
# Replace place holders in response file
cmd='su - $ORACLE_USER -c "$DB_HOME/bin/dbca -silent -ignorePreReqs -createDatabase -responseFile $responsefile"'
eval $cmd
rm -f $responsefile
}

checkDBStatus ()
{
local status

if [ -f "/tmp/db_status.txt" ]; then
status=$(cat /tmp/db_status.txt)
else
status="NOT OPEN"
fi

rm -f /tmp/db_status.txt

# SQL Plus execution was successful and database is open
if [ "$status" = "OPEN" ]; then
   print_message "#################################################################"
   print_message " Oracle Database $ORACLE_SID is up and running on $(hostname)    "
   print_message "#################################################################"
# Database is not open
else
   error_exit "$ORACLE_SID is not up and running on $(hostname)"
fi

}

setremotelistener ()
{
local status
local cmd

if resolveip $CMAN_HOSTNAME; then
print_message "Executing script to set the remote listener"
su - $ORACLE_USER -c "$SCRIPT_DIR/$REMOTE_LISTENER_FILE $ORACLE_SID $SCAN_NAME $CMAN_HOSTNAME.$DOMAIN"
fi

}

############################# DB Functions End here ###########################################

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

########
print_message "Process id of the program : $TOP_ID"
all_check
build_network
print_message "Setting random password for $GRID_USER user"
setpasswd $GRID_USER  $GRID_PASSWORD
print_message "Setting random password for $ORACLE_USER user"
setpasswd $ORACLE_USER $ORACLE_PASSWORD

print_message "Calling setupSSH function"
setupSSH
checkSSH

######### ASM Disk Setup #######
if [ "${CLUSTER_TYPE}" == 'DOMAIN' ] || [ "${CLUSTER_TYPE}" == 'STANDALONE' ]; then
build_block_device_list
build_gimr_block_device_list
setDevicePermissions
fi

####### Grid Setup ##########
print_message "Generating Reponsefile"
grid_response_file
print_message "Running cluvfy Checks"
cluvfy_checks
print_message "Running Grid Installation"
RunConfigGrid
print_message "Running root.sh"
runrootsh
print_message "Running post root.sh steps"
runpostrootsetps
print_message "Checking Cluster Status"
checkCluster

####### DB Setup ##########
if [ "${CLUSTER_TYPE}" == 'STANDALONE' ] || [ "${CLUSTER_TYPE}" == 'MEMBERDB' ]; then
print_message "Generating DB Responsefile Running DB creation"
dbca_response_file
print_message "Running DB creation"
createRACDB
print_message "Checking DB status"
su - $ORACLE_USER -c "$SCRIPT_DIR/$CHECK_DB_FILE $ORACLE_SID"
checkDBStatus
print_message "Running User Script"
su - $ORACLE_USER -c "$SCRIPT_DIR/$USER_SCRIPTS_FILE $SCRIPT_ROOT"
print_message "Setting Remote Listener"
setremotelistener
fi

echo $TRUE
