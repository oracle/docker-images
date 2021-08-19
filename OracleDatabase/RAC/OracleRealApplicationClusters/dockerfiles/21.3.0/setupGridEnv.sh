#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Pre-grid Setup tasks such as setting up hosts file
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

####################### Variabes and Constants #################
declare -r FALSE=1
declare -r TRUE=0
DNS_SERVER_FLAG='false'   # set this variable to true if you have DNS server. Then , it is not required to populate the /etc/hosts.
declare -r ETCHOSTS="/etc/hosts"  #
declare -r ETCFSTAB="/etc/fstab"
declare -x GRID_USER='grid'               ## Default user for grid installation
declare -r ASMADMIN_GROUP='asmadmin'      ## Default group for Grid.
declare -x PUBLIC_IP                      ## Computed based on Node name.
declare -x PUBLIC_HOSTNAME                ## PUBLIC HOSTNAME set based on hostname
declare -x NTPD_START='false'
declare -x RESOLV_CONF_FILE='/etc/resolv.conf'

progname="$(basename $0)"
######################## Variable and Constant declaration ends here ######

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

###################Capture Process id and source functions.sh###############
source "$SCRIPT_DIR/functions.sh"
###########################sourcing of functions.sh ends here##############

####error_exit function sends a TERM signal, which is caught by trap command and returns exit status 15"####
trap '{ exit 15; }' TERM
###########################trap code ends here##########################


######################################## Pre-Grid-Deployment Steps Begin here  #################################### 
pre_grid_deploy_steps ()
{
local systemd_svc
local systemctl_state

# Setting default gateway
if [ ! -z "${DEFAULT_GATEWAY}" ];then
  ip route del default
  ip route add default via $DEFAULT_GATEWAY 
fi

# Adding blank ntp.conf
touch /etc/ntp.conf

# Adding blank /etc/fstab
if [ ! -f ${ETCFSTAB} ]; then
 touch /etc/fstab
fi

# Changing permission for /common_scripts
if [ -d $COMMON_SCRIPTS ];
then
chown -R grid:oinstall ${COMMON_SCRIPTS}
chmod 775 ${COMMON_SCRIPTS}
fi

# Removing failed service as we systemd status 'running'

for systemd_svc in $(systemctl | grep failed | awk '{ print $2}')
do
   print_message "Disable failed service $systemd_svc"
   systemctl disable $systemd_svc
   print_message "Resetting Failed Services"
   systemctl reset-failed
done
systemctl reset-failed
# print_message "Sleeping for 60 seconds"
# sleep 60

systemctl_state=$(systemctl status | awk '/State:/{ print $0 }' | grep -v 'awk /State:/' | awk '{ print $2 }')

if [ "${systemctl_state}" == "running" ]; then
   print_message "Systemctl state is running!"
else
   error_exit "Systemctl state is $systemctl_state! it must be running state inside the container to proceed further"
fi

print_message "Setting correct permissions for /bin/ping"
chmod 6755 /bin/ping
chmod 6755 /usr/bin/ping
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


#if [ "${OP_TYPE}" == 'INSTALL' -o "${OP_TYPE}" == 'ADDNODE' ]; then
if [ ! -z "${ASM_DEVICE_LIST}" ]; then
print_message "Preapring Device list"
IFS=', ' read -r -a devices <<< "$ASM_DEVICE_LIST"
        local arr_device=${#devices[@]}
if [ $arr_device -ne 0 ]; then
        for device in "${devices[@]}"
        do
        	print_message "Changing Disk permission and ownership $device"
              if [ -e $device ]; then
        	chown $GRID_USER:$ASMADMIN_GROUP $device
	        chmod 660 $device
              else
                error_exit "Device $device does not exist! Please verify"
              fi
                count=$[$count+1]
       done
fi
else
	error_exit "ASM_DEVICE_LIST is set to empty cannot proceed"
fi
#fi


}

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

#if [ ${OP_TYPE} == 'INSTALL' ]; then
 if [ "${CLUSTER_TYPE}" == "DOMAIN" ]; then
   if  [ ! -z "${GIMR_DEVICE_LIST}" ]; then
	print_message "Preapring Device list"
	IFS=', ' read -r -a devices <<< "$GIMR_DEVICE_LIST"
        local arr_device=${#devices[@]}
	if [ $arr_device -ne 0 ]; then
	        for device in "${devices[@]}"
        	do
	        print_message "Changing Disk permission and ownership"
	        chown $GRID_USER:$ASMADMIN_GROUP $device
	        chmod 660 $device
	        count=$[$count+1]
	       done
	fi
else
        error_exit "GIMR_DEVICE_LIST is set to empty cannot proceed"
fi
fi
#fi
}

###################################### Setup Resolve.conf ###########################################################
setupResolvconf ()
{
local stat
local count=1
local temp_str

   if  [ ! -z "${DNS_SERVERS}" ]; then
        print_message "Preapring Dns Servers list"
        IFS=', ' read -r -a dns_servers <<< "$DNS_SERVERS"
        local arr_dns=${#dns_servers[@]}
        echo "search ${DOMAIN}" > ${RESOLV_CONF_FILE}
#       sed -i '/127.0.0.11/d' ${RESOLV_CONF_FILE}
        if [ $arr_dns -ne 0 ]; then
                for dns in "${dns_servers[@]}"
                do
                print_message "Setting DNS Servers"
                if grep -Fxq "${dns}" ${RESOLV_CONF_FILE}
                then
                   print_message "nameserver ${dns} exist in ${RESOLV_CONF_FILE}. No need to modify the ${RESOLV_CONF_FILE}."
		else
                   print_message "Adding nameserver ${dns} in ${RESOLV_CONF_FILE}."
                   echo  "nameserver ${dns}" >> ${RESOLV_CONF_FILE}
		fi 
               done
        fi
else
       print_message  "DNS_SERVERS is set to empty. /etc/resolv.conf will use default dns docker embedded server."
fi

}
####################################### Start NTPD ###################################################################
startNTPD()
{
if [ "${NTPD_START}" != 'false' ]; then
systemctl start ntpd
fi 
}
####################################### ETC Host Function #############################################################
checkHostName ()
{
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
}

SetupEtcHosts()
{
local stat=3
local HOST_LINE

if [ "${DNS_SERVER_FLAG}" == 'false' ]; then

if [ ! -z $HOSTFILE ]; then
cat $COMMON_SCRIPTS/$HOSTFILE > /etc/hosts
else
grep -P "127.0.0.1\tlocalhost.localdomain\tlocalhost" /etc/hosts
stat=$?

if [ $stat -eq 1 ]; then
echo -e "127.0.0.1\tlocalhost.localdomain\tlocalhost" > /etc/hosts
fi

for HOSTNAME  in $PUBLIC_HOSTNAME $PRIV_HOSTNAME $VIP_HOSTNAME $SCAN_NAME $EXISTING_CLS_NODE $CMAN_HOSTNAME $GNSVIP_HOSTNAME;
do
if [ -n "$(grep $HOSTNAME $ETCHOSTS)" ]; then
print_message "$HOSTNAME already exists : $(grep $HOSTNAME $ETCHOSTS), no $ETCHOST update required"
else
 print_message  "Preparing host line for $HOSTNAME";
 if [ "${HOSTNAME}" == "${PUBLIC_HOSTNAME}" ]; then
           unset HOST_LINE
           HOST_LINE="\n${PUBLIC_IP}\t${PUBLIC_HOSTNAME}.${DOMAIN}\t${PUBLIC_HOSTNAME}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
 elif [ "${HOSTNAME}" == "${PRIV_HOSTNAME}" ];then
           unset HOST_LINE
           HOST_LINE="\n${PRIV_IP}\t${PRIV_HOSTNAME}.${DOMAIN}\t${PRIV_HOSTNAME}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
 elif [ "${HOSTNAME}" == "${VIP_HOSTNAME}" ];then
           unset HOST_LINE
           HOST_LINE="\n${NODE_VIP}\t${VIP_HOSTNAME}.${DOMAIN}\t${VIP_HOSTNAME}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
 elif [ "${HOSTNAME}" == "${EXISTING_CLS_NODE}" ]; then
          unset HOST_LINE
           HOST_LINE="\n${EXISTING_CLS_NODE_IP}\t${EXISTING_CLS_NODE}.${DOMAIN}\t${EXISTING_CLS_NODE}"
           print_message "Adding $HOST_LINE to $ETCHOSTS"
           echo -e $HOST_LINE >> $ETCHOSTS
elif [ "${HOSTNAME}" == "${SCAN_NAME}" ]; then
        unset HOST_LINE
	if [ ! -z "$SCAN_IP" ];then
	  HOST_LINE="\n${SCAN_IP}\t${SCAN_NAME}.${DOMAIN}\t${SCAN_NAME}" 
          print_message "Adding $HOST_LINE to $ETCHOSTS"
          echo -e $HOST_LINE >> $ETCHOSTS
	fi
elif [ "${HOSTNAME}" == "${CMAN_HOSTNAME}" ]; then
        unset HOST_LINE
        if [ ! -z "$CMAN_IP" ];then
          HOST_LINE="\n${CMAN_IP}\t${CMAN_HOSTNAME}.${DOMAIN}\t${CMAN_HOSTNAME}"
          print_message "Adding $HOST_LINE to $ETCHOSTS"
          echo -e $HOST_LINE >> $ETCHOSTS
        fi
elif [ "${HOSTNAME}" == "${GNSVIP_HOSTNAME}" ]; then
        unset HOST_LINE
        if [ ! -z "$GNS_VIP" ];then
          HOST_LINE="\n${GNS_VIP}\t${GNSVIP_HOSTNAME}.${DOMAIN}\t${GNSVIP_HOSTNAME}"
          print_message "Adding $HOST_LINE to $ETCHOSTS"
          echo -e $HOST_LINE >> $ETCHOSTS
        fi
else
 print_message "HOSTNAME should match  any hostname in given hostnames $PUBLIC_HOSTNAME $PRIV_HOSTNAME $VIP_HOSTNAME $SCAN_NAME"
fi
fi
done
fi
#### DNS Server check ends below######
fi
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

########
print_message "Process id of the program : $TOP_ID"
##### start ntpd #######
startNTPD
pre_grid_deploy_steps
checkHostName
SetupEtcHosts
######### ASM Device Setup ########
build_block_device_list
build_gimr_block_device_list
####### Setup /etc/resolv.conf ######
setupResolvconf
print_message "#####################################################################"
print_message " RAC setup will begin in 2 minutes                                   "
print_message "####################################################################"
sleep 2
echo $TRUE
