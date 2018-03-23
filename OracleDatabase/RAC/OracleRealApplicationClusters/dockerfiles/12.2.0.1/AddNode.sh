#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Add a Grid node and add Oracle Database instance based on following parameters:
#              $PUBLIC_HOSTNAME
#              $PUBLIC_IP
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

source $SCRIPT_DIR/functions.sh

####################### Variabes and Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare ASM_DISKGROUP_DISKS
declare ASM_DISKGROUP_FG_DISKS
declare -r ETCHOSTS="/etc/hosts"
###################### Variables and Constants ####################


all_check()
{
check_env_vars
}

check_env_vars ()
{

################ Operations related to existing CLS nodes #######################
if [ -z "${EXISTING_CLS_NODES}" ]; then
	error_exit "For Node Addition, please provide the existing clustered nodes."
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

###########  Existing CLS node END here########################


if [ -z "${DOMAIN}" ]; then
   print_message  "Domain name is not defined. Setting Domain to 'example.com'"
    DOMAIN="example.com"
 else
 print_message "Domain is defined to $DOMAIN"
fi


## Checking Grid Reponsfile or vip,scan ip and private ip
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
   print_message "Container hostname ${PUBLIC_IP}"
fi

if [ -z "${PUBLIC_HOSTNAME}" ]; then
   error_exit "RAC Node PUBLIC Hostname is not set ot set to empty string"
else
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
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
print_message "Location for User script SCRIPT_ROOT set to empty"
else
print_message "Location for User script SCRIPT_ROOT set to $SCRIPT_ROOT"
fi

###### Check for Oracle SID ######

if [ -z "${ORACLE_SID}" ]; then
   print_message "ORACLE_SID is not defined"
else
  print_message "ORACLE_SID is set to $ORACLE_SID"
fi

}

########################################### SSH Function begin here ########################
setupSSH()
{
IFS=', ' read -r -a CLUSTER_NODES  <<< "$EXISTING_CLS_NODES"
EXISTING_CLS_NODES+=",$PUBLIC_HOSTNAME"
CLUSTER_NODES=$(echo $EXISTING_CLS_NODES | tr ',' ' ')

print_message "Cluster Nodes are $CLUSTER_NODES"

print_message "Running SSH setup for grid user between nodes ${CLUSTER_NODES}"
cmd='su - grid -c "$EXPECT $SCRIPT_DIR/$SETUPSSH grid \"$GRID_HOME/oui/prov/resources/scripts\"  \"${CLUSTER_NODES}\"  \"$OS_PASSWORD\""'
eval $cmd
sleep 30
print_message "Running SSH setup for oracle user between nodes ${CLUSTER_NODES[@]}"
cmd='su - oracle -c "$EXPECT $SCRIPT_DIR/$SETUPSSH oracle \"$DB_HOME/oui/prov/resources/scripts\"  \"${CLUSTER_NODES}\"  \"$OS_PASSWORD\""'
eval $cmd
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
$ORACLE_HOME/root.sh
}

generate_response_file ()
{
cp $SCRIPT_DIR/$ADDNODE_RSP $logdir/$ADDNODE_RSP
chmod 666 $logdir/$ADDNODE_RSP

if [ -z "${GRID_RESPONSE_FILE}" ]; then
sed -i -e "s|###INVENTORY###|$INVENTORY|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###GRID_BASE###|$GRID_BASE|g" $logdir/$ADDNODE_RSP
sed -i -r "s|###PUBLIC_HOSTNAME###|$PUBLIC_HOSTNAME|g"  $logdir/$ADDNODE_RSP
sed -i -r "s|###HOSTNAME_VIP###|$VIP_HOSTNAME|g"  $logdir/$ADDNODE_RSP
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

cmd='su - grid -c "ssh $node \"$ORACLE_HOME/bin/crsctl check crs\""'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check on remote node passed"
else
error_exit "Cluster Check on remote node failed"
fi

cmd='su - grid -c "ssh $node \"$ORACLE_HOME/bin/crsctl check cluster\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi

cmd='su - grid -c "ssh $node \"$ORACLE_HOME/bin/srvctl status mgmtdb\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "MGMTDB Check went fine"
else
error_exit "MGMTDB Check failed!"
fi

cmd='su - grid -c "ssh $node \"$ORACLE_HOME/bin/crsctl check crsd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi


cmd='su - grid -c "ssh $node \"$ORACLE_HOME/bin/crsctl check cssd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - grid -c "ssh $node \"$ORACLE_HOME/bin/crsctl check evmd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

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

###### Grid install & Cluster Verification utility Function #######
cluvfyCheck()
{

local node=$EXISTING_CLS_NODE
local responsefile=$logdir/$ADDNODE_RSP
local hostname=$PUBLIC_HOSTNAME
local vip_hostname=$VIP_HOSTNAME
local cmd
local stat

cmd='su - grid -c "ssh $node  \"$GRID_HOME/runcluvfy.sh stage -pre nodeadd -n $hostname -vip $vip_hostname\" | tee -a $logdir/cluvfy_check.txt"'
eval $cmd

if grep -q "FAILED" $logdir/cluvfy_check.txt
then
print_message "Cluster Verfication Check failed! Removing failure statement related to /etc/resov.conf, DNS and ntp.conf checks as DNS may  not be setup and CTSSD process will take care of time synchronization"
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
cat $logdir/cluvfy_check.txt >> $logfile
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
cmd='su - grid -c "scp $responsefile $node:$logdir"'
eval $cmd

print_message "Running GridSetup.sh on $node to add the node to existing cluster"
cmd='su - grid -c "ssh $node  \"$GRID_HOME/gridSetup.sh -silent -waitForCompletion -noCopy -skipPrereqs -responseFile $responsefile\" | tee -a $logfile"'
eval $cmd

print_message "Node Addition performed. removing Responsefile"
rm -f $responsefile
cmd='su - grid -c "ssh $node \"rm -f $responsefile\""'
eval $cmd

}

###########DB Node Addition Functions##############
addDBNode ()
{
local node=$EXISTING_CLS_NODE
local new_node_hostname=$PUBLIC_HOSTNAME
local stat=3
local cmd

cmd='su - oracle -c "ssh $node \"$DB_HOME/addnode/addnode.sh \"CLUSTER_NEW_NODES={$new_node_hostname}\" -skipPrereqs -waitForCompletion -ignoreSysPrereqs -noCopy  -silent\" | tee -a $logfile"'
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

if [ -z "${ORACLE_SID}" ];then
 error_exit "ORACLE SID is not defined. Cannot Add Instance"
fi

if [ -z "${HOSTNAME}" ]; then
error_exit "Hostname is not defined"
fi

cmd='su - oracle -c "ssh $node \"$DB_HOME/bin/dbca -addInstance -silent  -nodeName  $HOSTNAME -gdbName $ORACLE_SID\" | tee -a $logfile"'
eval $cmd
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

########################## DB Functions End here ##########################

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################


###### Etc Host and other Checks and setup before proceeding installation #####
all_check
print_message "Setting random password for root/grid/oracle user"
print_message "Setting random password for grid user"
setpasswd grid  $OS_PASSWORD
print_message "Setting random password for oracle user"
setpasswd oracle $OS_PASSWORD
print_message "Setting random password for root user"
setpasswd root $PASSWORD

####  Setting up SSH #######
setupSSH

#### Grid Node Addition #####
print_message "Checking Cluster Status on $EXISTING_CLS_NODE"
CheckRemoteCluster
print_message "Generating Responsefile for node addition"
generate_response_file
print_message "Running Cluster verification utility for new node $PUBLIC_HOSTNAME on $EXISTING_CLS_NODE"
cluvfyCheck
print_message "Running Node Addition and cluvfy test for node $PUBLIC_HOSTNAME"
addGridNode
print_message "Running root.sh on node $PUBLIC_HOSTNAME"
runrootsh $GRID_HOME 
checkCluster

###### DB Node Addition ######
print_message  "Performing DB Node addition"
addDBNode
print_message "Running root.sh"
runrootsh $DB_HOME
print_message "Adding DB Instance"
addDBInst 
print_message "Checking DB status"
su - oracle -c "$SCRIPT_DIR/$CHECK_DB_FILE $ORACLE_SID"
checkDBStatus
print_message "Running User Script"
su - oracle -c "$SCRIPT_DIR/$USER_SCRIPTS_FILE $SCRIPT_ROOT"
print_message "Setting Remote Listener"
setremotelistener
echo $TRUE
