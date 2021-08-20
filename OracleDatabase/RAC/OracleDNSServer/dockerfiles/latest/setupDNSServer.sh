#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2021 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2021
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
# Description: Runs  NFS server inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

source /tmp/envfile
source $SCRIPT_DIR/functions.sh

####################### Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -x HOSTNAME
declare -x RAC_PUBLIC_SUBNET
declare -x RAC_PRIVATE_SUBNET
declare -x RAC_PRIVATE_SUBNET2
declare -x RAC_PUBLIC_VIP_SUBNET
declare -x HOSTNAME_IP_LAST_DIGITS
declare -x DNS_SERVER_INSTALL_STATUS
declare -x RAC_DNS_SERVER_IP
declare -x IP_DIGIT_3
declare -x IP_DIGIT_2
declare -x IP_DIGIT_1
declare -x RAC_PUBLIC_REVERSE_IP
declare -x RAC_PRIVATE_REVERSE_IP
declare -x RAC_PRIVATE2_REVERSE_IP
declare -x DNS_SERVER_STATUS
export INSTALL_COMPLETED_FILE="/home/oracle/installcomplete"
export FILE_COUNT=0
##################################################

setEnvVariables()
{
    HOSTNAME=$(hostname | cut -d"." -f1)
    print_message "HOSTNAME is set to $HOSTNAME"
##    RAC_PUBLIC_SUBNET=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1-3)
    RAC_PUBLIC_SUBNET="192.168.17"
    print_message "RAC_PUBLIC_SUBNET is set to $RAC_PUBLIC_SUBNET"
##    RAC_PRIVATE_SUBNET=$(/sbin/ifconfig eth1 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1-3)
    RAC_PRIVATE_SUBNET="192.168.150"
    export RAC_PRIVATE_SUBNET
    print_message "RAC_PRIVATE_SUBNET is set to $RAC_PRIVATE_SUBNET"
    HOSTNAME_IP_LAST_DIGITS=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f4)
    print_message "HOSTNAME_IP_LAST_DIGITS is set to $HOSTNAME_IP_LAST_DIGITS"
    RAC_DNS_SERVER_IP=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
    print_message "RAC_DNS_SERVER_IP is set to $RAC_DNS_SERVER_IP"
    EXT_IP_DIGIT_3=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f3)
    EXT_IP_DIGIT_2=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f2)
    EXT_IP_DIGIT_1=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1)
    EXT_DNS_REVERSE_IP="${EXT_IP_DIGIT_3}.${EXT_IP_DIGIT_2}.${EXT_IP_DIGIT_1}"
    print_message "EXT_DNS_REVERSE_IP set to $EXT_DNS_REVERSE_IP"

    PUB_IP_DIGIT_3=`echo $RAC_PUBLIC_SUBNET | cut -d"." -f3`
    PUB_IP_DIGIT_2=`echo $RAC_PUBLIC_SUBNET | cut -d"." -f2`
    PUB_IP_DIGIT_1=`echo $RAC_PUBLIC_SUBNET | cut -d"." -f1`
    RAC_PUBLIC_REVERSE_IP="${PUB_IP_DIGIT_3}.${PUB_IP_DIGIT_2}.${PUB_IP_DIGIT_1}"
    print_message "RAC_PUBLIC_REVERSE_IP set to $RAC_PUBLIC_REVERSE_IP"
 
    PRIV_IP_DIGIT_3=`echo $RAC_PRIVATE_SUBNET | cut -d"." -f3`
    PRIV_IP_DIGIT_2=`echo $RAC_PRIVATE_SUBNET | cut -d"." -f2`
    PRIV_IP_DIGIT_1=`echo $RAC_PRIVATE_SUBNET | cut -d"." -f1`
    RAC_PRIVATE_REVERSE_IP="${PRIV_IP_DIGIT_3}.${PRIV_IP_DIGIT_2}.${PRIV_IP_DIGIT_1}"
    print_message "RAC_PRIVATE_REVERSE_IP set to $RAC_PRIVATE_REVERSE_IP"

    RAC_PRIVATE_SUBNET2="192.168.200"
    export RAC_PRIVATE_SUBNET2
    print_message "RAC_PRIVATE_SUBNET2 is set to $RAC_PRIVATE_SUBNET2"
    
    PRIV2_IP_DIGIT_3=`echo $RAC_PRIVATE_SUBNET2 | cut -d"." -f3`
    PRIV2_IP_DIGIT_2=`echo $RAC_PRIVATE_SUBNET2 | cut -d"." -f2`
    PRIV2_IP_DIGIT_1=`echo $RAC_PRIVATE_SUBNET2 | cut -d"." -f1`
    RAC_PRIVATE2_REVERSE_IP="${PRIV2_IP_DIGIT_3}.${PRIV2_IP_DIGIT_2}.${PRIV2_IP_DIGIT_1}"
    print_message "RAC_PRIVATE2_REVERSE_IP set to $RAC_PRIVATE2_REVERSE_IP"

    RAC_PUBLIC_VIP_SUBNET="192.168.18"
    export RAC_PUBLIC_VIP_SUBNET
    print_message "RAC_PUBLIC_VIP_SUBNET is set to $RAC_PUBLIC_VIP_SUBNET"

    VIP_IP_DIGIT_3=`echo $RAC_PUBLIC_VIP_SUBNET | cut -d"." -f3`
    VIP_IP_DIGIT_2=`echo $RAC_PUBLIC_VIP_SUBNET | cut -d"." -f2`
    VIP_IP_DIGIT_1=`echo $RAC_PUBLIC_VIP_SUBNET | cut -d"." -f1`
    PUBLIC_VIP_REVERSE_IP="${VIP_IP_DIGIT_3}.${VIP_IP_DIGIT_2}.${VIP_IP_DIGIT_1}"
    print_message "PUBLIC_VIP_REVERSE_IP set to $PUBLIC_VIP_REVERSE_IP"

    RAC_PUBLIC_SVIP_SUBNET="192.168.19"
    export RAC_PUBLIC_SVIP_SUBNET
    print_message "RAC_PUBLIC_SVIP_SUBNET is set to $RAC_PUBLIC_SVIP_SUBNET"

    SVIP_IP_DIGIT_3=`echo $RAC_PUBLIC_SVIP_SUBNET | cut -d"." -f3`
    SVIP_IP_DIGIT_2=`echo $RAC_PUBLIC_SVIP_SUBNET | cut -d"." -f2`
    SVIP_IP_DIGIT_1=`echo $RAC_PUBLIC_SVIP_SUBNET | cut -d"." -f1`
    PUBLIC_SVIP_REVERSE_IP="${SVIP_IP_DIGIT_3}.${SVIP_IP_DIGIT_2}.${SVIP_IP_DIGIT_1}"
    print_message "PUBLIC_SVIP_REVERSE_IP set to $PUBLIC_SVIP_REVERSE_IP"

    RAC_SCAN3_SUBNET="192.168.16"
    export RAC_SCAN3_SUBNET
    print_message "RAC_SCAN3_SUBNET is set to $RAC_SCAN3_SUBNET"

    SCAN_IP_DIGIT_3=`echo $RAC_SCAN3_SUBNET | cut -d"." -f3`
    SCAN_IP_DIGIT_2=`echo $RAC_SCAN3_SUBNET | cut -d"." -f2`
    SCAN_IP_DIGIT_1=`echo $RAC_SCAN3_SUBNET | cut -d"." -f1`
    SCAN3_REVERSE_IP="${SCAN_IP_DIGIT_3}.${SCAN_IP_DIGIT_2}.${SCAN_IP_DIGIT_1}"
    print_message "SCAN3_REVERSE_IP set to $SCAN3_REVERSE_IP"

    RAC_SCAN2_SUBNET="192.168.15"
    export RAC_SCAN2_SUBNET
    print_message "RAC_SCAN2_SUBNET is set to $RAC_SCAN2_SUBNET"

    SCAN_IP_DIGIT_3=`echo $RAC_SCAN2_SUBNET | cut -d"." -f3`
    SCAN_IP_DIGIT_2=`echo $RAC_SCAN2_SUBNET | cut -d"." -f2`
    SCAN_IP_DIGIT_1=`echo $RAC_SCAN2_SUBNET | cut -d"." -f1`
    SCAN2_REVERSE_IP="${SCAN_IP_DIGIT_3}.${SCAN_IP_DIGIT_2}.${SCAN_IP_DIGIT_1}"
    print_message "SCAN2_REVERSE_IP set to $SCAN2_REVERSE_IP"

    RAC_SCAN1_SUBNET="192.168.14"
    export RAC_SCAN1_SUBNET
    print_message "RAC_SCAN1_SUBNET is set to $RAC_SCAN1_SUBNET"

    SCAN_IP_DIGIT_3=`echo $RAC_SCAN1_SUBNET | cut -d"." -f3`
    SCAN_IP_DIGIT_2=`echo $RAC_SCAN1_SUBNET | cut -d"." -f2`
    SCAN_IP_DIGIT_1=`echo $RAC_SCAN1_SUBNET | cut -d"." -f1`
    SCAN1_REVERSE_IP="${SCAN_IP_DIGIT_3}.${SCAN_IP_DIGIT_2}.${SCAN_IP_DIGIT_1}"
    print_message "SCAN1_REVERSE_IP set to $SCAN1_REVERSE_IP"

    RAC_GNS_SUBNET="192.168.13"
    export RAC_GNS_SUBNET
    print_message "RAC_GNS_SUBNET is set to $RAC_GNS_SUBNET"

    GNS_IP_DIGIT_3=`echo $RAC_GNS_SUBNET | cut -d"." -f3`
    GNS_IP_DIGIT_2=`echo $RAC_GNS_SUBNET | cut -d"." -f2`
    GNS_IP_DIGIT_1=`echo $RAC_GNS_SUBNET | cut -d"." -f1`
    GNS_REVERSE_IP="${GNS_IP_DIGIT_3}.${GNS_IP_DIGIT_2}.${GNS_IP_DIGIT_1}"
    print_message "GNS_REVERSE_IP set to $GNS_REVERSE_IP"

    RAC_GNS_VIP_SUBNET="192.168.12"
    export RAC_GNS_VIP_SUBNET
    print_message "RAC_GNS_VIP_SUBNET is set to $RAC_GNS_VIP_SUBNET"

    GNS_IP_DIGIT_3=`echo $RAC_GNS_VIP_SUBNET | cut -d"." -f3`
    GNS_IP_DIGIT_2=`echo $RAC_GNS_VIP_SUBNET | cut -d"." -f2`
    GNS_IP_DIGIT_1=`echo $RAC_GNS_VIP_SUBNET | cut -d"." -f1`
    GNS_VIP_REVERSE_IP="${GNS_IP_DIGIT_3}.${GNS_IP_DIGIT_2}.${GNS_IP_DIGIT_1}"
    print_message "GNS_VIP_REVERSE_IP set to $GNS_VIP_REVERSE_IP"

    RAC_CMAN_SUBNET="192.168.100"
    export RAC_CMAN_SUBNET
    print_message "RAC_CMAN_SUBNET is set to $RAC_CMAN_SUBNET"

    CMAN_IP_DIGIT_3=`echo $RAC_CMAN_SUBNET | cut -d"." -f3`
    CMAN_IP_DIGIT_2=`echo $RAC_CMAN_SUBNET | cut -d"." -f2`
    CMAN_IP_DIGIT_1=`echo $RAC_CMAN_SUBNET | cut -d"." -f1`
    CMAN_REVERSE_IP="${CMAN_IP_DIGIT_3}.${CMAN_IP_DIGIT_2}.${CMAN_IP_DIGIT_1}"
    print_message "CMAN_REVERSE_IP set to $CMAN_REVERSE_IP"

    if [ -z ${DOMAIN_NAME} ]; then
       error_exit "DOMAIN_NAME env variable is set to empty. Exiting.."
   fi

    if [ -z ${PRIVATE_DOMAIN_NAME} ]; then
       error_exit "PRIVATE_DOMAIN_NAME env variable is set to empty. Exiting.."
   fi

    if [ -z ${RAC_NODE_NAME_PREFIX} ]; then
       error_exit "RAC_NODE_NAME_PREFIX env variable is set to empty."
   fi

  if [ -z ${SETUP_DNS_CONFIG_FILES} ]; then
       error_exit "SETUP_DNS_CONFIG_FILES set to empty."
  fi

   print_message "Creating Directories"
   mkdir -p ${ZONE_FILE_LOC_2}
   mkdir -p ${ZONE_FILE_LOC_2}/data
   touch    ${ZONE_FILE_LOC_2}/data/named.run
   mkdir -p ${NAMED_CHROOT_ETC_DIR}
}

setupZoneFile ()
{
   print_message "Setting up Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_NODE_NAME_PREFIX###|$RAC_NODE_NAME_PREFIX|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_PUBLIC_VIP_SUBNET###|$RAC_PUBLIC_VIP_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_PUBLIC_SVIP_SUBNET###|$RAC_PUBLIC_SVIP_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_PUBLIC_SUBNET###|$RAC_PUBLIC_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_SCAN1_SUBNET###|$RAC_SCAN1_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_SCAN2_SUBNET###|$RAC_SCAN2_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_SCAN3_SUBNET###|$RAC_SCAN3_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_GNS_SUBNET###|$RAC_GNS_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_GNS_VIP_SUBNET###|$RAC_GNS_VIP_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_CMAN_SUBNET###|$RAC_CMAN_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
}

setupReverseZonefile()
{
   print_message "Setting up reverse Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_NODE_NAME_PREFIX###|$RAC_NODE_NAME_PREFIX|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###PUBLIC_VIP_REVERSEIP###|$PUBLIC_VIP_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###PUBLIC_SVIP_REVERSEIP###|$PUBLIC_SVIP_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_PUBLIC_REVERSEIP###|$RAC_PUBLIC_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###SCAN1_REVERSEIP###|$SCAN1_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###SCAN2_REVERSEIP###|$SCAN2_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###SCAN3_REVERSEIP###|$SCAN3_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###GNS_REVERSEIP###|$GNS_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###GNS_VIP_REVERSEIP###|$GNS_VIP_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###CMAN_REVERSEIP###|$CMAN_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###EXT_DNS_REVERSEIP###|$EXT_DNS_REVERSE_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone

}

setupPrivateZoneFile ()
{
   print_message "Setting up Private Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###DOMAIN_NAME###|$PRIVATE_DOMAIN_NAME|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###PRIVATE_DOMAIN_NAME###|$PRIVATE_DOMAIN_NAME|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_NODE_NAME_PREFIX###|$RAC_NODE_NAME_PREFIX|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_PRIVATE_SUBNET###|$RAC_PRIVATE_SUBNET|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_PRIVATE_SUBNET2###|$RAC_PRIVATE_SUBNET2|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone
}

setupPrivateReverseZonefile()
{
   print_message "Setting up Private reverse Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###DOMAIN_NAME###|$PRIVATE_DOMAIN_NAME|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_NODE_NAME_PREFIX###|$RAC_NODE_NAME_PREFIX|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_PRIVATE_REVERSEIP###|$RAC_PRIVATE_REVERSE_IP|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###PRIVATE2_REVERSEIP###|$RAC_PRIVATE2_REVERSE_IP|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###EXT_DNS_REVERSEIP###|$EXT_DNS_REVERSE_IP|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
}

setupNamed()
{
   print_message "Setting ip named configuration file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###PRIVATE_DOMAIN_NAME###|$PRIVATE_DOMAIN_NAME|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###RAC_NODE_NAME_PREFIX###|$RAC_NODE_NAME_PREFIX|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###REVERSEIP###|$RAC_PUBLIC_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###EXT_DNS_REVERSEIP###|$EXT_DNS_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###SCAN1_REVERSEIP###|$SCAN1_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###SCAN2_REVERSEIP###|$SCAN2_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###SCAN3_REVERSEIP###|$SCAN3_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###GNS_REVERSEIP###|$GNS_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###GNS_VIP_REVERSEIP###|$GNS_VIP_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###CMAN_REVERSEIP###|$CMAN_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###PUBLIC_VIP_REVERSEIP###|$PUBLIC_VIP_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###PUBLIC_SVIP_REVERSEIP###|$PUBLIC_SVIP_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###PRIVATE_REVERSEIP###|$RAC_PRIVATE_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###PRIVATE2_REVERSEIP###|$RAC_PRIVATE2_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###NAMED_SAMPLE_FILE###|$NAMED_SAMPLE_FILE|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_CONF_FILE
}

CopyFiles()
{
   print_message "Copying files to destination dir"
   cp $SCRIPT_DIR/$NAMED_CONF_FILE ${NAMED_CHROOT_ETC_DIR}/$NAMED_CONF_FILE
   cp $SCRIPT_DIR/$NAMED_SAMPLE_FILE  ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   cp $SCRIPT_DIR/$REVERSE_ZONE_FILE $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   cp $SCRIPT_DIR/$ZONEFILE $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone 
   cp $SCRIPT_DIR/$PRIVATE_REVERSE_ZONE_FILE $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone
   cp $SCRIPT_DIR/$PRIVATE_ZONEFILE $ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone 
   cp $SCRIPT_DIR/$NAMED_LOCALHOST_FILE  ${ZONE_FILE_LOC_2}/ 
   cp /var/named/$NAMED_LOOPBACK_FILE ${ZONE_FILE_LOC_2}/
   cp /var/named/$NAMED_EMPTY_FILE  ${ZONE_FILE_LOC_2}/
   chown -R root:named ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   chown -R root:named ${NAMED_CHROOT_ETC_DIR}/$NAMED_CONF_FILE
   chown -R root:named $ZONE_FILE_LOC_2
   chown -R named:named $ZONE_FILE_LOC_2/data
}

setupResolveconf ()
{
print_message "Setting up Resolve.conf file"
echo "search $DOMAIN_NAME $PRIVATE_DOMAIN_NAME" > /etc/resolv.conf
echo "nameserver  $RAC_DNS_SERVER_IP" >> /etc/resolv.conf
}

startDNSServer ()
{
print_message "Starting DNS Server"
/usr/sbin/named -u named -c /etc/${NAMED_CONF_FILE} -t ${NAMED_CHROOT_ROOT_DIR}
#systemctl start named-chroot

print_message "Checking DNS Server"
nslookup $HOSTNAME.$DOMAIN_NAME

if [ $? -eq 0 ];then
print_message "DNS Server started sucessfully"
else
error_exit "DNS Server startup failed"
fi
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

if [ ${SETUP_DNS_CONFIG_FILES} == 'setup_true' ]; then
   print_message "Starting DNS Server setup" >> $logfile
   setEnvVariables
   CopyFiles
   setupZoneFile
   setupReverseZonefile
   setupPrivateZoneFile
   setupPrivateReverseZonefile
   setupNamed
   setupResolveconf
else
   CopyFiles
fi
startDNSServer

print_message "################################################"
print_message " DNS Server IS READY TO USE!            "
print_message "################################################"
