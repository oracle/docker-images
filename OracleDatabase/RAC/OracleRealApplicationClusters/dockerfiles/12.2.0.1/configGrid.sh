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
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

source $SCRIPT_DIR/functions.sh 

####################### Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -r ETCHOSTS="/etc/hosts"
declare ASM_DISKGROUP_DISKS
declare ASM_DISKGROUP_FG_DISKS
declare PUB_IP_NETMASK
declare PRIV_IP_NETMASK
declare ETH_CARD_1
declare ETH_CARD_2
declare PUBLIC_NETWORK
declare PRIVATE_NETWORK
progname="$(basename $0)"
###################### Constants ####################

all_check()
{
check_env_vars
}

check_env_vars ()
{
## Checking Grid Reponsfile or vip,scan ip and private ip
### if user has passed the Grid ResponseFile name, below checks will be skipped

# Following checks will be executed if user is not providing Grid Response File

if [ -z "${DOMAIN}" ]; then
   print_message  "Domain name is not defined. Setting Domain to 'example.com'"
    DOMAIN="example.com"
 else
 print_message "Domain is defined to $DOMAIN"
fi


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

if [ -z "${PUBLIC_IP}" ]; then
    error_exit  "Container hostname is not set or set to the empty string"
else
    print_message "Public IP is set to ${PUBLIC_IP}"
fi

if [ -z "${PUBLIC_HOSTNAME}" ]; then
   error_exit "RAC Node PUBLIC Hostname is not set ot set to empty string"
else
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
fi

if [ -z ${SCAN_NAME} ]; then
  error_exit "SCAN_NAME set to the empty string"
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

if [ -z ${PASSWORD} ]; then
   print_message "Password is empty string"
   PASSWORD=O$(openssl rand -base64 6 | tr -d "=+/")_1
else
  print_message "Password string is set"
fi

if [ -z ${OS_PASSWORD} ]; then
   print_message "OS_Password is empty string for Oracle and grid. Setting to system generated password"
   OS_PASSWORD=$PASSWORD
else
  print_message "OS Password string is set for Grid and Oracle user"
fi


if [ -z ${CLUSTER_NAME} ]; then
   print_message "Cluster Name is not defined"
   print_message "Cluster name is set to 'racnode-c'"
   CLUSTER_NAME="racnode-c"
else
  print_message "Cluset name is set to $CLUSTER_NAME"
fi

##### Checks for VIP, Scan, Priv Hostname ENS here #######

if [ -z "${GRID_RESPONSE_FILE}" ];then
print_message "GRID_RESPONSE_FILE env variable set to empty. $progname will use standard cluster responsefile"
else
if [ -f $COMMON_SCRIPTS/$GRID_RESPONSE_FILE ];then
cp $COMMON_SCRIPTS/$GRID_RESPONSE_FILE $logdir/$GRID_INSTALL_RSP
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

if [ -z "${ORACLE_PWD}" ]; then
export ORACLE_PWD="$PASSWORD"
fi

if [ -z "${ORACLE_CHARACTERSET}" ]; then
export ORACLE_CHARACTERSET="AL32UTF8"
else
print_message "DB characterset set to $ORACLE_CHARACTERSET"
fi

}


########################################### SSH Function begin here ########################
setupSSH()
{
local CLUSTER_NODES=$PUBLIC_HOSTNAME

print_message "Running SSH setup for grid user between nodes $CLUSTER_NODES"
cmd='su - grid -c "$EXPECT $SCRIPT_DIR/$SETUPSSH grid \"$GRID_HOME/oui/prov/resources/scripts\"  \"$CLUSTER_NODES\" \"$OS_PASSWORD\""'
eval $cmd
sleep 30
print_message "Running SSH setup for oracle user between nodes $CLUSTER_NODES"
cmd='su - oracle -c "$EXPECT $SCRIPT_DIR/$SETUPSSH oracle \"$DB_HOME/oui/prov/resources/scripts\"  \"$CLUSTER_NODES\" \"$OS_PASSWORD\""'
eval $cmd
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

if [ ! -z "${ASM_DEVICE_LIST}" ];then

print_message "Preapring Device list"
IFS=', ' read -r -a devices <<< "$ASM_DEVICE_LIST"
        local arr_device=${#devices[@]}
if [ $arr_device -ne 0 ]; then
        for device in "${devices[@]}"
        do
        ASM_DISKGROUP_FG_DISKS+="$device,,"
        ASM_DISKGROUP_DISKS+="$device,"
        ((size+=$(blockdev --getsize64 $device)))
        print_message "Disks size (bytes) : $size"
        print_message "Changing Disk permission and ownership"
        chown grid:asmadmin $device
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
}

######################################### ASM Disk Functions ####################################

####################################### Network Function Begin here #############################
build_network ()
{

if [ -z "${GRID_RESPONSE_FILE}" ]; then

####### Building Public IP Details ###########
ETH_CARD_2=$(ifconfig | awk "/${PUBLIC_IP}/ {print $1}"  RS="\n\n" | awk -F ":" '{ print $1 }' | head -1)

if check_interface $ETH_CARD_2 ; then
  print_message "Check passed for network card"
 else
 error_exit "Check failed for network card"
 fi

PUBLIC_NETMASK=$(ifconfig $ETH_CARD_2  | awk '/netmask/ {print $4}')
print_message "Public Netmask : $PUBLIC_NETMASK"
PUBLIC_NETWORK=$(ipcalc -np $PUBLIC_IP $PUBLIC_NETMASK | grep NETWORK | awk -F '=' '{ print $2 }')

##### Building Private Network Detail #########

ETH_CARD_1=$(ifconfig | awk "/${PRIV_IP}/ {print $1}" RS="\n\n" | awk -F ":" '{ print $1 }' | head -1)

if check_interface $ETH_CARD_1 ; then
  print_message "Check passed for network card"
else
 error_exit "Check failed for network card"
fi

PRIVATE_NETMASK=$(ifconfig $ETH_CARD_1  | awk '/netmask/ {print $4}')
PRIVATE_NETWORK=$(ipcalc -np $PRIV_IP $PRIVATE_NETMASK | grep NETWORK | awk -F '=' '{ print $2 }')

fi

}

########################################## Network Function End here ################################

######### Grid setup Function###########################
grid_response_file ()
{

if [ -z $GRID_RESPONSE_FILE ]; then
cp $SCRIPT_DIR/$GRID_INSTALL_RSP $logdir/$GRID_INSTALL_RSP
#chmod 777 $logdir

sed -i -e "s|###INVENTORY###|$INVENTORY|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###CLUSTER_NAME###|$CLUSTER_NAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###GRID_BASE###|$GRID_BASE|g" $logdir/$GRID_INSTALL_RSP
sed -i -e "s|###SCAN_NAME###|$SCAN_NAME|g" $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###HOSTNAME###|$PUBLIC_HOSTNAME|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###HOSTNAME_VIP###|$VIP_HOSTNAME|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###ETH_CARD1###|$ETH_CARD_1|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###ETH_CARD2###|$ETH_CARD_2|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###PRIVATE_SUBNET###|$PRIVATE_NETWORK|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###PUBLIC_SUBNET###|$PUBLIC_NETWORK|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###ASM_DISKGROUP_FG_DISKS###|$ASM_DISKGROUP_FG_DISKS|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###ASM_DISKGROUP_DISKS###|$ASM_DISKGROUP_DISKS|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###ASM_DISCOVERY_STRING###|$ASM_DISCOVERY_DIR/*|g"  $logdir/$GRID_INSTALL_RSP
sed -i -r "s|###PASSWORD###|$ORACLE_PWD|g"  $logdir/$GRID_INSTALL_RSP
fi

}

cluvfy_checks ()
{
local responsefile=$logdir/$GRID_INSTALL_RSP
local password=$PASSWORD
local stat=3
local cmd

print_message "Performing Cluvfy Checks"
cmd='su - grid -c "$GRID_HOME/runcluvfy.sh stage -pre crsinst -responseFile $responsefile | tee -a  $logdir/cluvfy_check.txt"'
eval $cmd

if grep -q "FAILED" $logdir/cluvfy_check.txt
then
print_message "Cluster Verfication Check failed! Removing failure statement related to /etc/resov.conf, DNS and ntp.conf checks as you may not have DNS or NTP Server"
sed -i '/DNS\/NIS/d'  $logdir/cluvfy_check.txt
sed -i '/resolv.conf/d' $logdir/cluvfy_check.txt
sed -i '/Network Time Protocol/d' $logdir/cluvfy_check.txt
print_message "Checking Again $logdir/cluvfy_check.txt"
#####
if grep -q "FAILED" $logdir/cluvfy_check.txt
then
error_exit "Pre Checks failed for Grid installation, please check $logdir/cluvfy_check.txt"
fi
######
print_message "Pre Checks failed for Grid installation, ignoring failure related to SCAN and /etc/resolv.conf"
else
print_message "Pre Checks passed for Grid installation. You can check cvu checks under $logdir/cluvfy_check.txt"
fi
}

RunConfigGrid()
{
local responsefile=$logdir/$GRID_INSTALL_RSP
local password=$PASSWORD
local stat=3
local cmd

echo $password > $logdir/pass
cmd='su - grid -c "$GRID_HOME/gridSetup.sh -waitforcompletion -ignorePrereq  -silent -responseFile $responsefile < $logdir/pass"'
eval $cmd

rm -f $logdir/pass
rm -f $responsefile
}

checkCluster ()
{
local cmd;
local stat;
local oracle_home=$GRID_HOME

print_message "Checking Cluster"

cmd='su - grid -c "$GRID_HOME/bin/crsctl check crs"'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check passed"
else
error_exit "Cluster Check failed"
fi

cmd='su - grid -c "$GRID_HOME/bin/crsctl check cluster"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi

cmd='su - grid -c "$GRID_HOME/bin/srvctl status mgmtdb"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "MGMTDB Check went fine"
else
error_exit "MGMTDB Check failed!"
fi

cmd='su - grid -c "$GRID_HOME/bin/crsctl check crsd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi

cmd='su - grid -c "$GRID_HOME/bin/crsctl check cssd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - grid -c "$GRID_HOME/bin/crsctl check evmd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

print_message "Removing $logdir/cluvfy_check.txt as cluster check has passed"
rm -f $logdir/cluvfy_check.txt

}

#############DB Setup Functions########################################

dbca_response_file ()
{

if [ -z $DBCA_RESPONSE_FILE ]; then
cp $SCRIPT_DIR/$DBCA_RSP $logdir/$DBCA_RSP
chmod 666 $logdir/$DBCA_RSP

sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $logdir/$DBCA_RSP
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $logdir/$DBCA_RSP
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $logdir/$DBCA_RSP
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" $logdir/$DBCA_RSP
sed -i -e "s|###PUBLIC_HOSTNAME###|$PUBLIC_HOSTNAME|g" $logdir/$DBCA_RSP
sed -i -e "s|##DB_BASE####|$DB_BASE|g" $logdir/$DBCA_RSP
sed -i -e "s|###DB_HOME###|$DB_HOME|g" $logdir/$DBCA_RSP

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
cmd='su - oracle -c "$DB_HOME/bin/dbca -silent -ignorePreReqs -createDatabase -responseFile $responsefile"'
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
su - oracle -c "$SCRIPT_DIR/$REMOTE_LISTENER_FILE $ORACLE_SID $SCAN_NAME $CMAN_HOSTNAME.$DOMAIN"
fi

}

############################# DB Functions End here ###########################################

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

########
all_check
build_network
print_message "Setting random password for grid user"
setpasswd grid  $OS_PASSWORD
print_message "Setting random password for oracle user"
setpasswd oracle $OS_PASSWORD
print_message "Setting random password for root user"
setpasswd root $PASSWORD
print_message "Calling setupSSH function"
setupSSH

######### ASM Disk Setup #######
build_block_device_list

####### Grid Setup ##########
print_message "Generating Reponsefile"
grid_response_file
print_message "Running cluvfy Checks"
cluvfy_checks
print_message "Running Grid Installation"
RunConfigGrid
print_message "Checking Cluster Status"
checkCluster

####### DB Setup ##########
print_message "Generating DB Responsefile Running DB creation"
dbca_response_file
print_message "Running DB creation"
createRACDB
print_message "Checking DB status"
su - oracle -c "$SCRIPT_DIR/$CHECK_DB_FILE $ORACLE_SID"
checkDBStatus
print_message "Running User Script"
su - oracle -c "$SCRIPT_DIR/$USER_SCRIPTS_FILE $SCRIPT_ROOT"
print_message "Setting Remote Listener"
setremotelistener
echo $TRUE
