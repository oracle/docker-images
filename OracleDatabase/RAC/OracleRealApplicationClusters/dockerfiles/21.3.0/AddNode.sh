#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Add a Grid node and add Oracle Database instance based on following parameters:
#              $PUBLIC_HOSTNAME
#              $PUBLIC_IP
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

####################### Variables and Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -x GRID_USER='grid'          ## Default gris user is grid.
declare -x DB_USER='oracle'      ## default oracle user is oracle.
declare -r ETCHOSTS="/etc/hosts"     ## /etc/hosts file location.
declare -r RAC_ENV_FILE="/etc/rac_env_vars"   ## RACENV FILE NAME
declare -x GIMR_DB_FLAG='false'      ## GIMR DB Check by default is false
declare -x DOMAIN                    ## Domain name will be computed based on hostname -d, otherwise pass it as env variable.
declare -x PUBLIC_IP                 ## Computed based on Node name.
declare -x PUBLIC_HOSTNAME           ## PUBLIC HOSTNAME set based on hostname
declare -x EXISTING_CLS_NODE         ## Computed during the program execution.
declare -x EXISTING_CLS_NODES        ## You must all the exisitng nodes of the cluster in comma separated strings. Otherwise installation will fail.
declare -x DHCP_CONF='false'         ## Pass env variable where value set to true for DHCP based installation.
declare -x NODE_VIP                  ## Pass it as env variable.
declare -x VIP_HOSTNAME              ## Pass as env variable.
declare -x SCAN_NAME                 ## Pass it as env variable.
declare -x SCAN_IP                   ## Pass as env variable if you do not have DNS server. Otherwise, do not pass this variable.
declare -x SINGLENIC='false'         ## Default value is false as we should use 2 nics if possible for better performance.
declare -x PRIV_IP                   ## Pass PRIV_IP is not using SINGLE NIC
declare -x CONFIGURE_GNS='false'     ## Default value set to false. However, under DSC checks, it is reverted to true.
declare -x COMMON_SCRIPTS            ## COMMON SCRIPT Locations. Pass this env variable if you have custom responsefile for grid and other scripts for DB.
declare -x PRIV_HOSTNAME             ## if SINGLENIC=true then PRIV and PUB hostname will be same. Otherise pass it as env variable.
declare -x CMAN_HOSTNAME             ## If you want to use connection manager to proxy the DB connections
declare -x CMAN_IP                   ## CMAN_IP if you want to use connection manager to proxy the DB connections
declare -x OS_PASSWORD               ## if not passed as env variable, it will be set to PASSWORD
declare -x GRID_PASSWORD             ## if not passed as env variable , it will be set to OS_PASSWORD
declare -x ORACLE_PASSWORD           ## if not passed as env variable, it will be set to OS_PASSWORD
declare -x PASSWORD                  ## If not passed as env variable , it will be set as system generated password
declare -x CLUSTER_TYPE='STANDARD'   ## Default instllation is STANDARD. You can pass DOMAIn or MEMBERDB.
declare -x GRID_RESPONSE_FILE        ## IF you pass this env variable then user based responsefile will be used. default location is COMMON_SCRIPTS.
declare -x SCRIPT_ROOT               ## SCRIPT_ROOT will be set as per your COMMON_SCRIPTS.Do not Pass env variable SCRIPT_ROOT.
declare -r OSDBA='dba'
declare -r OSASM='asmadmin'
declare -r INSTALL_TYPE='CRS_ADDNODE'
declare -r IPMI_FLAG='false'
declare -r ASM_STORAGE_OPTION='ASM'
declare -r GIMR_ON_NAS='false'
declare -x SCAN_TYPE='LOCAL_SCAN'
declare -x SHARED_SCAN
declare -x DB_ASM_DISKGROUP='DATA'
declare -x CONFIGURE_AFD_FLAG='false'
declare -x CONFIGURE_RHPS_FLAG='false'
declare -x EXECUTE_ROOT_SCRIPT_FLAG='fasle'
declare -x EXECUTE_ROOT_SCRIPT_METHOD='ROOT'
declare -x IGNORE_CVU_CHECKS='true'           ## Ignore CVU Checks
declare -x SECRET_VOLUME='/run/secrets/'      ## Secret Volume
declare -x PWD_KEY='pwd.key'                  ## PWD Key File
declare -x ORACLE_PWD_FILE
declare -x GRID_PWD_FILE
declare -x REMOVE_OS_PWD_FILES='false'
declare -x COMMON_OS_PWD_FILE='common_os_pwdfile.enc'
declare -x CRS_CONFIG_NODES
declare -x ANSIBLE_INSTALL='false'
declare -x RUN_DBCA='true'

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

all_check()
{
check_pub_host_name
check_cls_node_names
check_ip_env_vars
check_passwd_env_vars
check_rspfile_env_vars
check_db_env_vars
}

#####################Function related to public hostname, IP and domain name check begin here ########

check_pub_host_name()
{
local domain_name
local stat

if [ -z "${PUBLIC_IP}" ]; then
    PUBLIC_IP=$(dig +short "$(hostname)")
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

############### Function related to public hostname, IP and domain checks ends here ##########

############## Function related to check exisitng cls nodes begin here #######################
check_cls_node_names()
{
if [ -z "${EXISTING_CLS_NODES}" ]; then
	error_exit "For Node Addition, please provide the existing clustered node name."
else
	
   if isStringExist ${EXISTING_CLS_NODES} ${PUBLIC_HOSTNAME}; then
	  error_exit "EXISTING_CLS_NODES ${EXISTING_CLS_NODES} contains new node name ${PUBLIC_HOSTNAME}"
   fi

print_message "Setting Existing Cluster Node for node addition operation. This will be retrieved from ${EXISTING_CLS_NODES}"

EXISTING_CLS_NODE="$( cut -d ',' -f 1 <<< "$EXISTING_CLS_NODES" )"

if [ -z "${EXISTING_CLS_NODE}" ]; then
   error_exit " Existing Node Name of the cluster not set or set to empty string"
else
   print_message "Existing Node Name of the cluster is set to ${EXISTING_CLS_NODE}"

if resolveip ${EXISTING_CLS_NODE}; then
 print_message "Existing Cluster node resolved to IP. Check passed"
else
  error_exit "Existing Cluster node does not resolved to IP. Check Failed"
fi
fi
fi
}

############## Function related to check exisitng cls nodes begin here #######################

check_ip_env_vars ()
{
if [ "${DHCP_CONF}" != 'true' ]; then
  print_message "Default setting of AUTO GNS VIP set to false. If you want to use AUTO GNS VIP, please pass DHCP_CONF as an env parameter set to true"
  DHCP_CONF=false
if [ -z "${NODE_VIP}" ]; then
   error_exit "RAC Node ViP is not set or set to empty string"
else
   print_message "RAC VIP set to ${NODE_VIP}"
fi

if [ -z "${VIP_HOSTNAME}" ]; then
   error_exit "RAC Node Vip hostname is not set ot set to empty string"
else
   print_message "RAC Node VIP hostname is set to ${VIP_HOSTNAME} "
fi

if [ -z ${SCAN_NAME} ]; then
  print_message "SCAN_NAME set to the empty string"
else
  print_message "SCAN_NAME name is ${SCAN_NAME}"
fi

if resolveip ${SCAN_NAME}; then
 print_message "SCAN Name resolving to IP. Check Passed!"
else
  error_exit "SCAN Name not resolving to IP. Check Failed!"
fi

if [ -z ${SCAN_IP} ]; then
   print_message "SCAN_IP set to the empty string"
else
  print_message "SCAN_IP name is ${SCAN_IP}"
fi
fi

if [ "${SINGLENIC}" == 'true' ];then
PRIV_IP=${PUBLIC_IP}
PRIV_HOSTNAME=${PUBLIC_HOSTNAME}
fi

if [ -z "${PRIV_IP}" ]; then
   error_exit "RAC Node private ip is not set ot set to empty string"
else
  print_message "RAC Node PRIV IP is set to ${PRIV_IP} "
fi

if [ -z "${PRIV_HOSTNAME}" ]; then
   error_exit "RAC Node private hostname is not set ot set to empty string"
else
  print_message "RAC Node private hostname is set to ${PRIV_HOSTNAME}"
fi


if [ -z ${CMAN_HOSTNAME} ]; then
  print_message  "CMAN_NAME set to the empty string"
else
  print_message "CMAN_HOSTNAME name is ${CMAN_HOSTNAME}"
fi

if [ -z ${CMAN_IP} ]; then
   print_message "CMAN_IP set to the empty string"
else
  print_message "CMAN_IP name is ${CMAN_IP}"
fi

}
################check ip env vars function  ends here ############################

################ Check passwd env vars function  begin here ######################
check_passwd_env_vars()
{
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

if [ "${REMOVE_OS_PWD_FILES}" == 'true' ]; then
rm -f  ${SECRET_VOLUME}/${COMMON_OS_PWD_FILE}
rm -f ${SECRET_VOLUME}/${PWD_KEY}
fi

}

############### Check password env vars function ends here ########################

############### Check grid Response file function begin here ######################
check_rspfile_env_vars ()
{
if [ -z "${GRID_RESPONSE_FILE}" ];then
print_message "GRID_RESPONSE_FILE env variable set to empty. $progname will use standard cluster responsefile"
else
if [ -f $COMMON_SCRIPTS/$GRID_RESPONSE_FILE ];then
cp $COMMON_SCRIPTS/$GRID_RESPONSE_FILE $logdir/$GRID_RESPONSE_FILE
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

}

############ Check responsefile function end here ######################

########### Check db env vars function begin here #######################
check_db_env_vars ()
{
if [ $CLUSTER_TYPE == 'MEMBERDB' ]; then
print_message "Checking StorageOption for MEMBERDB Cluster"

if [ -z "${STORAGE_OPTIONS_FOR_MEMBERDB}" ]; then
print_message "Storage Options is set to STORAGE_OPTIONS_FOR_MEMBERDB"
else
print_message "Storage Options is set to STORAGE_OPTIONS_FOR_MEMBERDB"
fi

fi
if [ -z "${ORACLE_SID}" ]; then
   print_message "ORACLE_SID is not defined"
else
  print_message "ORACLE_SID is set to $ORACLE_SID"
fi

}

################# Check db env vars end here ##################################

################ All Check Functions end here #####################################


########################################### SSH Function begin here ########################
setupSSH()
{
local password
local ssh_pid
local stat

if [ -z $CRS_NODES ]; then
  CRS_NODES=$PUBLIC_HOSTNAME
fi


IFS=', ' read -r -a CLUSTER_NODES  <<< "$EXISTING_CLS_NODES"
EXISTING_CLS_NODES+=",$CRS_NODES"
CLUSTER_NODES=$(echo $EXISTING_CLS_NODES | tr ',' ' ')

print_message "Cluster Nodes are $CLUSTER_NODES"
print_message "Running SSH setup for $GRID_USER user between nodes ${CLUSTER_NODES}"
cmd='su - $GRID_USER -c "$EXPECT $SCRIPT_DIR/$SETUPSSH $GRID_USER \"$GRID_HOME/oui/prov/resources/scripts\"  \"${CLUSTER_NODES}\"  \"$GRID_PASSWORD\""'
(eval $cmd) &
ssh_pid=$!
wait $ssh_pid
stat=$?

if [ "${stat}" -ne 0 ]; then
error_exit "ssh setup for Grid user failed!, please make sure you have pass the corect password. You need to make sure that password must be same on all the clustered nodes or the nodes set in existing_cls_nodes env variable for $GRID_USER  user"
fi

print_message "Running SSH setup for $DB_USER user between nodes ${CLUSTER_NODES[@]}"
cmd='su - $DB_USER -c "$EXPECT $SCRIPT_DIR/$SETUPSSH $DB_USER \"$DB_HOME/oui/prov/resources/scripts\"  \"${CLUSTER_NODES}\"  \"$ORACLE_PASSWORD\""'
(eval $cmd) &
ssh_pid=$!
wait $ssh_pid
stat=$?

if [ "${stat}" -ne 0 ]; then
error_exit "ssh setup for Oracle user failed!, please make sure you have pass the corect password. You need to make sure that password must be same on all the clustered nodes or the nodes set in existing_cls_nodes env variable for $DB_USER user"
fi
}

checkSSH ()
{

local password
local ssh_pid
local stat
local status

IFS=', ' read -r -a CLUSTER_NODES  <<< "$EXISTING_CLS_NODES"
EXISTING_CLS_NODES+=",$PUBLIC_HOSTNAME"
CLUSTER_NODES=$(echo $EXISTING_CLS_NODES | tr ',' ' ')

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
cmd='su - $DB_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $DB_USER@$node echo ok 2>&1"'
 echo $cmd
for node in ${CLUSTER_NODES}
do

status=$(eval $cmd)

if [[ $status == ok ]] ; then
  print_message "SSH check fine for the $DB_USER@$node"
elif [[ $status == "Permission denied"* ]] ; then
   error_exit "SSH check failed for the $DB_USER@$node becuase of permission denied error! SSH setup did not complete sucessfully"
else
   error_exit "SSH check failed for the $DB_USER@$node! Error occurred during SSH setup"
fi

done

}

######################################  SSH Function End here ####################################

######################Add Node Functions ####################################
runorainstroot()
{
$INVENTORY/orainstRoot.sh
}

runrootsh ()
{

local ORACLE_HOME=$1
local USER=$2

if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  IFS=', ' read -r -a CLUSTER_NODES <<< "$CRS_NODES"
fi

print_message "Nodes in the cluster ${CLUSTER_NODES[@]}"
for node in "${CLUSTER_NODES[@]}"; do
cmd='su - $USER -c "ssh $node sudo $ORACLE_HOME/root.sh"'
eval $cmd
done

}

generate_response_file ()
{
cp $SCRIPT_DIR/$ADDNODE_RSP $logdir/$ADDNODE_RSP
chmod 666 $logdir/$ADDNODE_RSP

if [ -z "${GRID_RESPONSE_FILE}" ]; then

if [ -z ${CRS_CONFIG_NODES} ]; then
   CRS_CONFIG_NODES="$PUBLIC_HOSTNAME:$VIP_HOSTNAME:HUB"
   print_message "Clustered Nodes are set to $CRS_CONFIG_NODES"
fi

sed -i -e "s|###INVENTORY###|$INVENTORY|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###GRID_BASE###|$GRID_BASE|g" $logdir/$ADDNODE_RSP
sed -i -r "s|###PUBLIC_HOSTNAME###|$PUBLIC_HOSTNAME|g"  $logdir/$ADDNODE_RSP
sed -i -r "s|###HOSTNAME_VIP###|$VIP_HOSTNAME|g"  $logdir/$ADDNODE_RSP
sed -i -e "s|###INSTALL_TYPE###|$INSTALL_TYPE|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###OSDBA###|$OSDBA|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###OSOPER###|$OSOPER|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###OSASM###|$OSASM|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###SCAN_TYPE###|$SCAN_TYPE|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###SHARED_SCAN_FILE###|$SHARED_SCAN_FILE|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###DB_ASM_DISKGROUP###|$DB_ASM_DISKGROUP|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###CONFIGURE_AFD_FLAG###|$CONFIGURE_AFD_FLAG|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###CONFIGURE_RHPS_FLAG###|$CONFIGURE_RHPS_FLAG|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###EXECUTE_ROOT_SCRIPT_FLAG###|$EXECUTE_ROOT_SCRIPT_FLAG|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###EXECUTE_ROOT_SCRIPT_METHOD###|$EXECUTE_ROOT_SCRIPT_METHOD|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###CRS_CONFIG_NODES###|$CRS_CONFIG_NODES|g" $logdir/$ADDNODE_RSP
else
print_message "Copying $COMMON_SCRIPTS/$GRID_RESPONSE_FILE $logdir/$ADDNODE_RSP"
cp $COMMON_SCRIPTS/$GRID_RESPONSE_FILE $logdir/$ADDNODE_RSP
chmod 666 $logdir/$ADDNODE_RSP
fi

}

###### Cluster Verification function #######
CheckRemoteCluster ()
{
local cmd;
local stat;
local node=$EXISTING_CLS_NODE
local oracle_home=$GRID_HOME
local ORACLE_HOME=$GRID_HOME

print_message "Checking Cluster"

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check crs\""'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check on remote node passed"
else
error_exit "Cluster Check on remote node failed"
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check cluster\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi

if [ ${GIMR_DB_FLAG} == 'true' ]; then

   cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/srvctl status mgmtdb\""'
   eval $cmd

    if [ $? -eq 0 ]; then
        print_message "MGMTDB Check went fine"
    else
         error_exit "MGMTDB Check failed!"
    fi
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check crsd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi


cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check cssd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check evmd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

}

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
        cmd='su - $GRID_USER -c "ssh $node sudo echo \"export GIMR_DEVICE_LIST=${GIMR_DEVICE_LIST}\" >> /etc/rac_env_vars"'
        print_message "Command : $cmd execute on $node"
        eval $cmd
        unset cmd
       done
fi

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
        cmd='su - $GRID_USER -c "ssh $node sudo echo \"export ASM_DEVICE_LIST=${ASM_DEVICE_LIST}\" >> /etc/rac_env_vars"'
        print_message "Command : $cmd execute on $node"
        eval $cmd
        unset cmd
       done
fi

fi

done

}

checkCluster ()
{
local cmd;
local stat;
local oracle_home=$GRID_HOME

print_message "Checking Cluster"

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check crs"'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check passed"
else
error_exit "Cluster Check failed"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check cluster"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi

if [ ${GIMR_DB_FLAG} == 'true' ]; then
   cmd='su - $GRID_USER -c "$GRID_HOME/bin/srvctl status mgmtdb"'
    eval $cmd

   if [ $? -eq 0 ]; then
      print_message "MGMTDB Check went fine"
   else
      error_exit "MGMTDB Check failed!"
    fi
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check crsd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check cssd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check evmd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

print_message "Removing $logdir/cluvfy_check.txt as cluster check has passed"
rm -f $logdir/cluvfy_check.txt

}

checkClusterClass ()
{
print_message "Checking Cluster Class"
local cluster_class

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl get cluster class"'
cluster_class=$(eval $cmd)
print_message "Cluster class is $cluster_class"
CLUSTER_TYPE=$(echo $cluster_class | awk -F \' '{ print $2 }' | awk '{ print $1 }')
}


###### Grid install & Cluster Verification utility Function #######
cluvfyCheck()
{

local node=$EXISTING_CLS_NODE
local responsefile=$logdir/$ADDNODE_RSP
local hostname=$PUBLIC_HOSTNAME
local vip_hostname=$VIP_HOSTNAME
local cmd
local stat

if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  IFS=', ' read -r -a CLUSTER_NODES <<< "$CRS_NODES"
fi

if [ -f "$logdir/cluvfy_check.txt" ]; then
print_message "Moving any exisiting cluvfy $logdir/cluvfy_check.txt to $logdir/cluvfy_check_$TIMESTAMP.txt"
mv $logdir/cluvfy_check.txt $logdir/cluvfy_check."$(date +%Y%m%d-%H%M%S)".txt
fi

#cmd='su - $GRID_USER -c "ssh $node  \"$GRID_HOME/runcluvfy.sh stage -pre nodeadd -n $hostname -vip $vip_hostname\" | tee -a $logdir/cluvfy_check.txt"'
#eval $cmd

print_message "Nodes in the cluster ${CLUSTER_NODES[@]}"
for cls_node in "${CLUSTER_NODES[@]}"; do
print_message "ssh to the node $node and executing cvu checks on $cls_node"
cmd='su - $GRID_USER -c "ssh $node  \"$GRID_HOME/runcluvfy.sh stage -pre nodeadd -n $cls_node\" | tee -a $logdir/cluvfy_check.txt"'
eval $cmd
done

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

addGridNode ()
{

local node=$EXISTING_CLS_NODE
local responsefile=$logdir/$ADDNODE_RSP
local hostname=$PUBLIC_HOSTNAME
local vip_hostname=$VIP_HOSTNAME
local cmd
local stat

print_message "Copying $responsefile on remote node $node"
cmd='su - $GRID_USER -c "scp $responsefile $node:$logdir"'
eval $cmd

print_message "Running GridSetup.sh on $node to add the node to existing cluster"
cmd='su - $GRID_USER -c "ssh $node  \"$GRID_HOME/gridSetup.sh -silent -waitForCompletion -noCopy -skipPrereqs -responseFile $responsefile\" | tee -a $logfile"'
eval $cmd

print_message "Node Addition performed. removing Responsefile"
rm -f $responsefile
cmd='su - $GRID_USER -c "ssh $node \"rm -f $responsefile\""'
#eval $cmd

}

###########DB Node Addition Functions##############
addDBNode ()
{
local node=$EXISTING_CLS_NODE

if [ -z $CRS_NODES ]; then
   new_node_hostname=$PUBLIC_HOSTNAME
else
   new_node_hostname=$CRS_NODES
fi

local stat=3
local cmd

cmd='su - $DB_USER -c "ssh $node \"$DB_HOME/addnode/addnode.sh \"CLUSTER_NEW_NODES={$new_node_hostname}\" -skipPrereqs -waitForCompletion -ignoreSysPrereqs -noCopy  -silent\" | tee -a $logfile"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Node Addition went fine for $new_node_hostname"
else
error_exit "Node Addition failed for $new_node_hostname"
fi
}

addDBInst ()
{
# Check whether ORACLE_SID is passed on
local HOSTNAME=$PUBLIC_HOSTNAME
local node=$EXISTING_CLS_NODE
local stat=3
local cmd

if [ -z $CRS_NODES ]; then
  CLUSTER_NODES=$PUBLIC_HOSTNAME
else
  CLUSTER_NODES=$( echo $CRS_NODES | tr ',' ' ' )
fi

if [ -z "${ORACLE_SID}" ];then
 error_exit "ORACLE SID is not defined. Cannot Add Instance"
fi

if [ -z "${HOSTNAME}" ]; then
error_exit "Hostname is not defined"
fi


for new_node in "${CLUSTER_NODES[@]}"; do
print_message "Adding DB Instance on $node"
cmd='su - $DB_USER -c "ssh $node \"$DB_HOME/bin/dbca -addInstance -silent  -nodeName $new_node  -gdbName $ORACLE_SID\" | tee -a $logfile"'
eval $cmd
done

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
su - $DB_USER -c "$SCRIPT_DIR/$REMOTE_LISTENER_FILE $ORACLE_SID $SCAN_NAME $CMAN_HOSTNAME.$DOMAIN"
fi

}

########################## DB Functions End here ##########################

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################


###### Etc Host and other Checks and setup before proceeding installation #####
all_check
print_message "Setting random password for root/$GRID_USER/$DB_USER user"
print_message "Setting random password for $GRID_USER user"
setpasswd $GRID_USER  $GRID_PASSWORD
print_message "Setting random password for $DB_USER user"
setpasswd $DB_USER $ORACLE_PASSWORD
print_message "Setting random password for root user"
setpasswd root $PASSWORD

####  Setting up SSH #######
setupSSH
checkSSH

#### Grid Node Addition #####
print_message "Setting Device permission to grid and asmadmin on all the cluster nodes"
setDevicePermissions
print_message "Checking Cluster Status on $EXISTING_CLS_NODE"
CheckRemoteCluster
print_message "Generating Responsefile for node addition"
generate_response_file
print_message "Running Cluster verification utility for new node $PUBLIC_HOSTNAME on $EXISTING_CLS_NODE"
cluvfyCheck
print_message "Running Node Addition and cluvfy test for node $PUBLIC_HOSTNAME"
addGridNode
print_message "Running root.sh on node $PUBLIC_HOSTNAME"
runrootsh $GRID_HOME  $GRID_USER
checkCluster
print_message "Checking Cluster Class"
checkClusterClass

###### DB Node Addition ######
if [ "${CLUSTER_TYPE}" != 'Domain' ]; then
if [ "${RUN_DBCA}" == 'true' ]; then
print_message  "Performing DB Node addition"
addDBNode
print_message "Running root.sh"
runrootsh $DB_HOME $DB_USER
print_message "Adding DB Instance"
addDBInst 
print_message "Checking DB status"
su - $DB_USER -c "$SCRIPT_DIR/$CHECK_DB_FILE $ORACLE_SID"
checkDBStatus
print_message "Running User Script"
su - $DB_USER -c "$SCRIPT_DIR/$USER_SCRIPTS_FILE $SCRIPT_ROOT"
print_message "Setting Remote Listener"
setremotelistener
fi
fi
echo $TRUE
