#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Pre-grid Setup tasks such as setting up hosts file
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
progname="$(basename $0)"
###################### Constants ####################


######################################## Pre-Grid-Deployment Steps Begin here  #################################### 
pre_grid_deploy_steps ()
{

# Setting default gateway
if [ ! -z "${DEFAULT_GATEWAY}" ];then
ip route del default
ip route add default via $DEFAULT_GATEWAY 
fi

# Adding blank ntp.conf
touch /etc/ntp.conf
}
##################################### Pre-Grid-Deployment steps end here ############################
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
}


####################################### ETC Host Function #############################################################



SetupEtcHosts()
{
local stat=3
local HOST_LINE

if [ ! -z $HOSTFILE ]; then
cat $SCRIPT_DIR/$HOSTFILE > /etc/hosts
else
grep -P "127.0.0.1\tlocalhost.localdomain\tlocalhost" /etc/hosts
stat=$?

if [ $stat -eq 1 ]; then
echo -e "127.0.0.1\tlocalhost.localdomain\tlocalhost" > /etc/hosts
fi

for HOSTNAME  in $PUBLIC_HOSTNAME $PRIV_HOSTNAME $VIP_HOSTNAME $SCAN_NAME $EXISTING_CLS_NODE $CMAN_HOSTNAME;
do
if [ -n "$(grep $HOSTNAME $ETCHOSTS)" ]; then
print_message "$HOSTNAME already exists : $(grep $HOSTNAME $ETCHOSTS), no $ETCHOST update required"
else
 print_message  "Preparing hos line for $HOSTNAME";
 if [ "${HOSTNAME}" == "${PUBLIC_HOSTNAME}" ]; then
           unset HOST_LINE
           HOST_LINE="${PUBLIC_IP}\t${PUBLIC_HOSTNAME}.${DOMAIN}\t${PUBLIC_HOSTNAME}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
 elif [ "${HOSTNAME}" == "${PRIV_HOSTNAME}" ];then
           unset HOST_LINE
           HOST_LINE="${PRIV_IP}\t${PRIV_HOSTNAME}.${DOMAIN}\t${PRIV_HOSTNAME}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
 elif [ "${HOSTNAME}" == "${VIP_HOSTNAME}" ];then
           unset HOST_LINE
           HOST_LINE="${NODE_VIP}\t${VIP_HOSTNAME}.${DOMAIN}\t${VIP_HOSTNAME}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
 elif [ "${HOSTNAME}" == "${EXISTING_CLS_NODE}" ]; then
          unset HOST_LINE
           HOST_LINE="${EXISTING_CLS_NODE_IP}\t${EXISTING_CLS_NODE}.${DOMAIN}\t${EXISTING_CLS_NODE}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
elif [ "${HOSTNAME}" == "${SCAN_NAME}" ]; then
        unset HOST_LINE
	if [ ! -z "$SCAN_IP" ];then
	  HOST_LINE="${SCAN_IP}\t${SCAN_NAME}.${DOMAIN}\t${SCAN_NAME}" 
          print_message "Adding $HOST_LINE to $ETCHOSTS"
          echo -e $HOST_LINE >> $ETCHOSTS
	fi
elif [ "${HOSTNAME}" == "${CMAN_HOSTNAME}" ]; then
        unset HOST_LINE
        if [ ! -z "$CMAN_IP" ];then
          HOST_LINE="${CMAN_IP}\t${CMAN_HOSTNAME}.${DOMAIN}\t${CMAN_HOSTNAME}"
          print_message "Adding $HOST_LINE to $ETCHOSTS"
          echo -e $HOST_LINE >> $ETCHOSTS
        fi
else
 print_message "HOSTNAME should match  any hostname in given hostnames $PUBLIC_HOSTNAME $PRIV_HOSTNAME $VIP_HOSTNAME $SCAN_NAME"
fi
fi
done

fi
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

########
pre_grid_deploy_steps
SetupEtcHosts
######### ASM Device Setup ########
print_message "Building block device. if $ASM_DEVICE_LIST is set then ASM Disk permission will be set"
build_block_device_list
print_message "#####################################################################"
print_message " RAC setup will begin in 2 minutes                                   "
print_message "####################################################################"
sleep 120
echo $TRUE
