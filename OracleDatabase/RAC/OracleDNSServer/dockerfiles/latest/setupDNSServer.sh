#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com,  paramdeep.saini@oracle.com
# Description:
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
declare -x HOSTNAME_IP_LAST_DIGITS
declare -x DNS_SERVER_INSTALL_STATUS
declare -x RAC_DNS_SERVER_IP
declare -x IP_DIGIT_3
declare -x IP_DIGIT_2
declare -x IP_DIGIT_1
declare -x RAC_PUBLIC_REVERSE_IP
declare -x DNS_SERVER_STATUS
export INSTALL_COMPLETED_FILE="/home/oracle/installcomplete"
export FILE_COUNT=0
##################################################

setEnvVariables()
{
    HOSTNAME=$(hostname | cut -d"." -f1)
    print_message "HOSTNAME is set to $HOSTNAME"
    RAC_PUBLIC_SUBNET=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1-3)
    print_message "RAC_PUBLIC_SUBNET is set to $RAC_PUBLIC_SUBNET"
    HOSTNAME_IP_LAST_DIGITS=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f4)
    print_message "HOSTNAME_IP_LAST_DIGITS is set to $HOSTNAME_IP_LAST_DIGITS"
    RAC_DNS_SERVER_IP=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
    print_message "RAC_DNS_SERVER_IP is set to $RAC_DNS_SERVER_IP"
    IP_DIGIT_3=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f3)
    IP_DIGIT_2=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f2)
    IP_DIGIT_1=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1)
    RAC_PUBLIC_REVERSE_IP="${IP_DIGIT_3}.${IP_DIGIT_2}.${IP_DIGIT_1}"
    print_message "RAC_PUBLIC_REVERSE_IP set to $RAC_PUBLIC_REVERSE_IP"

    if [ -z ${DOMAIN_NAME} ]; then
       error_exit "DOMAIN_NAME env variable is set to empty. Existing.."
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
   sed -i -e "s|###RAC_PUBLIC_SUBNET###|$RAC_PUBLIC_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone
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
   sed -i -e "s|###RAC_PUBLIC_SUBNET###|$RAC_PUBLIC_SUBNET|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" $ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone
}

setupNamed()
{
   print_message "Setting ip named configuration file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###RAC_NODE_NAME_PREFIX###|$RAC_NODE_NAME_PREFIX|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
   sed -i -e "s|###REVERSEIP###|$RAC_PUBLIC_REVERSE_IP|g" ${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE
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
echo "search $DOMAIN_NAME" > /etc/resolv.conf
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
   setupNamed
   setupResolveconf
else
   CopyFiles
fi
startDNSServer

print_message "################################################"
print_message " DNS Server IS READY TO USE!            "
print_message "################################################"
