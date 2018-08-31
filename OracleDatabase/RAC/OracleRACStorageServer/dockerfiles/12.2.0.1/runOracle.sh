#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
# Description: Runs  NFS server inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi
logfile="/tmp/orod.log"

touch $logfile
chmod 666 /tmp/orod.log
progname="$(basename $0)"

####################### Constants #################
declare -r FALSE=1
declare -r TRUE=0
export REQUIRED_SPACE_GB=55
export ORADATA=/oradata
export INSTALL_COMPLETED_FILE="/home/oracle/installcomplete"
export FILE_COUNT=0
##################################################

check_space ()
{
local REQUIRED_SPACE_GB=$1

AVAILABLE_SPACE_GB=`df -B 1G $ORADATA | tail -n 1 | awk '{print $4}'`
if [ ! -f ${INSTALL_COMPLETED_FILE} ] ;then
if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
  script_name=`basename "$0"`
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "$script_name: ERROR - There is not enough space available in the docker container under $ORADATA."
  echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB , but only $AVAILABLE_SPACE_GB available."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1;
else
 echo " Space check passed : $ORADATA has avilable space $AVAILABLE_SPACE_GB and ASM storage set to $REQUIRED_SPACE_GB"
fi;
fi;
}

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
local cmd
echo "Stopping nfs server"
sudo /usr/sbin/rpc.nfsd 0
echo "Executing exportfs au"
sudo /usr/sbin/exportfs -au
echo "Executing exportfs f"
sudo /usr/sbin/exportfs -f
touch /tmp/stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down!"
local cmd
echo "Stopping nfs server"
sudo /usr/sbin/rpc.nfsd 0
echo "Executing exportfs au"
sudo /usr/sbin/exportfs -au
echo "Executing exportfs f"
sudo /usr/sbin/exportfs -f
touch /tmp/sigterm
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down database!"
local cmd
echo "Stopping nfs server"
sudo /usr/sbin/rpc.nfsd 0
echo "Executing exportfs au"
sudo /usr/sbin/exportfs -au
echo "Executing exportfs f"
sudo /usr/sbin/exportfs -f
touch /tmp/sigkill
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

if [ ! -d "$ORADATA" ] ;then
echo "$ORADATA dir doesn't exist! exiting"
exit 1
fi

if [  -z $ASM_STORAGE_SIZE_GB ] ;then
echo "ASM_STORAGE_SIZE env variable is not defined! Assining 50GB default"
ASM_STORAGE_SIZE_GB=50
else
echo "ASM STORAGE SIZE set to : $ASM_STORAGE_SIZE_GB"
fi

echo "Oracle user will be the owner for /oradata"
sudo chown -R oracle:oinstall /oradata

echo "Checking Space"
check_space $ASM_STORAGE_SIZE_GB
ASM_DISKS_SIZE=$(($ASM_STORAGE_SIZE_GB/5))
count=1;
while [ $count -le 5 ];
do
echo "Creating ASM Disks $ORADATA/asm_disk0$count.img of size $ASM_DISKS_SIZE"

if [ ! -f $ORADATA/asm_disk0$count.img ];then
dd if=/dev/zero of=$ORADATA/asm_disk0$count.img bs=1G count=$ASM_DISKS_SIZE
else
echo "$ORADATA/asm_disk0$count.img file already exist! Skipping file creation"
fi

count=$(($count+1))
done

FILE_COUNT=$(ls $ORADATA/asm_disk0* | wc -l)

if [ ${FILE_COUNT} -ge 5 ];then
echo "Touching ${INSTALL_COMPLETED_FILE}"
touch ${INSTALL_COMPLETED_FILE}
fi

echo "#################################################"
echo " Starting NFS Server Setup                       "
echo "#################################################"


echo "Setting up /etc/exports"
cat $SCRIPT_DIR/$EXPORTFILE | sudo tee -a /etc/exports

echo "Starting RPC Bind "
sudo /sbin/rpcbind -w
	
echo "Exporting File System"
sudo /usr/sbin/exportfs -r

echo "Starting RPC NFSD"
sudo /usr/sbin/rpc.nfsd

echo "Starting RPC Mountd"
sudo /usr/sbin/rpc.mountd --manage-gids		

#echo "Starting Rpc Quotad"
sudo /usr/sbin/rpc.rquotad

echo "Checking NFS server"
PROC_COUNT=`ps aux | egrep 'rpcbind|mountd|nfsd' | grep -v "grep -E rpcbind|mountd|nfsd" | wc -l`

if [ $PROC_COUNT -gt 1 ]; then
echo "####################################################"
echo " NFS Server is up and running                       "
echo " Create NFS volume for $ORADATA/$ORACLE_SID         "
echo "####################################################"
echo $TRUE
else
echo "NFS Server Setup Failed"
fi

tail -f /tmp/orod.log &
childPID=$!
wait $childPID
