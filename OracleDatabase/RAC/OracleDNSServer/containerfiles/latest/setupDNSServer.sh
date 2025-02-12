#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018-2025 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
# Description: Runs  NFS server inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# shellcheck disable=SC1091
source /tmp/envfile
# shellcheck disable=SC1090
source "$SCRIPT_DIR/functions.sh"

####################### Constants #################
declare -x HOSTNAME
declare -x RAC_PUBLIC_SUBNET
declare -x RAC_PRIVATE_SUBNET
declare -x HOSTNAME_IP_LAST_DIGITS
declare -x DNS_SERVER_INSTALL_STATUS
declare -x RAC_DNS_SERVER_IP
declare -x IP_DIGIT_3
declare -x IP_DIGIT_2
declare -x IP_DIGIT_1
declare -x RAC_PUBLIC_REVERSE_IP
declare -x RAC_PRIVATE_REVERSE_IP
declare -x DNS_SERVER_STATUS
declare -x prefixdSet
declare -x prefixpSet
export INSTALL_COMPLETED_FILE="/home/oracle/installcomplete"
export FILE_COUNT=0
##################################################

setEnvVariables()
{
    prefixdSet=0
    prefixpSet=0
    HOSTNAME=$(hostname | cut -d"." -f1)
    print_message "HOSTNAME is set to $HOSTNAME"
    RAC_PUBLIC_SUBNET=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1-3)
    print_message "RAC_PUBLIC_SUBNET is set to $RAC_PUBLIC_SUBNET"

if [ -n "${PRIVATE_DOMAIN_NAME}" ]; then
    RAC_PRIVATE_SUBNET=$(/sbin/ifconfig eth1 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1-3)
    export RAC_PRIVATE_SUBNET
    print_message "RAC_PRIVATE_SUBNET is set to $RAC_PRIVATE_SUBNET"
fi
    HOSTNAME_IP_LAST_DIGITS=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f4)
    print_message "HOSTNAME_IP_LAST_DIGITS is set to $HOSTNAME_IP_LAST_DIGITS"
    RAC_DNS_SERVER_IP=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
    print_message "RAC_DNS_SERVER_IP is set to $RAC_DNS_SERVER_IP"
    IP_DIGIT_3=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f3)
    IP_DIGIT_2=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f2)
    IP_DIGIT_1=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | cut -d"." -f1)
    RAC_PUBLIC_REVERSE_IP="${IP_DIGIT_3}.${IP_DIGIT_2}.${IP_DIGIT_1}"
    print_message "RAC_PUBLIC_REVERSE_IP set to $RAC_PUBLIC_REVERSE_IP"
 
    PRIV_IP_DIGIT_3=$(echo "$RAC_PRIVATE_SUBNET" | cut -d"." -f3)
    PRIV_IP_DIGIT_2=$(echo "$RAC_PRIVATE_SUBNET" | cut -d"." -f2)
    PRIV_IP_DIGIT_1=$(echo "$RAC_PRIVATE_SUBNET" | cut -d"." -f1)
    RAC_PRIVATE_REVERSE_IP="${PRIV_IP_DIGIT_3}.${PRIV_IP_DIGIT_2}.${PRIV_IP_DIGIT_1}"
    print_message "RAC_PRIVATE_REVERSE_IP set to $RAC_PRIVATE_REVERSE_IP"

    if [ -z "${DOMAIN_NAME}" ]; then

       error_exit "DOMAIN_NAME env variable is set to empty. Exiting.."
    fi

    if [ -z "${PRIVATE_DOMAIN_NAME}" ]; then
       print_message "PRIVATE_DOMAIN_NAME env variable is not set.."
    fi

    if [ -z "${RAC_NODE_NAME_PREFIXD}" ]; then
       print_message "RAC_NODE_NAME_PREFIXD env variable is set to empty."
    else
       print_message "RAC_NODE_NAME_PREFIXD env variable is set to ${RAC_NODE_NAME_PREFIXD}."
       prefixdSet=1
    fi

   if [ -z "${RAC_NODE_NAME_PREFIXP}" ]; then
       print_message "RAC_NODE_NAME_PREFIXP env variable is set to empty."
   else
       print_message "RAC_NODE_NAME_PREFIXP env variable is set to ${RAC_NODE_NAME_PREFIXP}."
       prefixpSet=1
   fi
   # shellcheck disable=SC2153
   if [ -n "${RAC_NODE_NAME_PREFIX}" ]; then
       print_message "RAC_NODE_NAME_PREFIX env variable is set to ${RAC_NODE_NAME_PREFIX}."
       RAC_NODE_NAME_PREFIXD="${RAC_NODE_NAME_PREFIX}DMY"
       RAC_NODE_NAME_PREFIXP=${RAC_NODE_NAME_PREFIX}
   else
       # shellcheck disable=SC2166
       if [ $prefixdSet -eq 0 -a $prefixpSet -eq 0 ]; then
          error_exit "Set atleast one of RAC_NODE_NAME_PREFIXD,RAC_NODE_NAME_PREFIXP or RAC_NODE_NAME_PREFIX.Exiting.."
       fi
   fi

  if [ -z "${SETUP_DNS_CONFIG_FILES}" ]; then
       error_exit "SETUP_DNS_CONFIG_FILES set to empty."
  fi

   print_message "Creating Directories"
   mkdir -p "${ZONE_FILE_LOC_2}"
   mkdir -p "${ZONE_FILE_LOC_2}/data"
   touch    "${ZONE_FILE_LOC_2}/data/named.run"
   mkdir -p "${NAMED_CHROOT_ETC_DIR}"
}

setupZoneFile ()
{
   print_message "Setting up Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXD###|$RAC_NODE_NAME_PREFIXD|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXP###|$RAC_NODE_NAME_PREFIXP|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_PUBLIC_SUBNET###|$RAC_PUBLIC_SUBNET|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
}

setupReverseZonefile()
{
   print_message "Setting up reverse Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXD###|$RAC_NODE_NAME_PREFIXD|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXP###|$RAC_NODE_NAME_PREFIXP|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_PUBLIC_SUBNET###|$RAC_PUBLIC_SUBNET|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
}

setupPrivateZoneFile ()
{
   print_message "Setting up Private Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###PRIVATE_DOMAIN_NAME###|$PRIVATE_DOMAIN_NAME|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXD###|$RAC_NODE_NAME_PREFIXD|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXP###|$RAC_NODE_NAME_PREFIXP|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_PRIVATE_SUBNET###|$RAC_PRIVATE_SUBNET|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
}

setupPrivateReverseZonefile()
{
   print_message "Setting up Private reverse Zone file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXD###|$RAC_NODE_NAME_PREFIXD|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXP###|$RAC_NODE_NAME_PREFIXP|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_PUBLIC_SUBNET###|$RAC_PUBLIC_SUBNET|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   sed -i -e "s|###HOSTNAME_IP_LAST_DIGITS###|$HOSTNAME_IP_LAST_DIGITS|g" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
}

setupNamed()
{
   print_message "Setting ip named configuration file"
   sed -i -e "s|###HOSTNAME###|$HOSTNAME|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   sed -i -e "s|###DOMAIN_NAME###|$DOMAIN_NAME|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
if [ -n "${PRIVATE_DOMAIN_NAME}" ]; then
   sed -i -e "s|###PRIVATE_DOMAIN_NAME###|$PRIVATE_DOMAIN_NAME|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   sed -i -e "s|###PRIVATE_REVERSEIP###|$RAC_PRIVATE_REVERSE_IP|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
fi
   sed -i -e "s|###RAC_NODE_NAME_PREFIXD###|$RAC_NODE_NAME_PREFIXD|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   sed -i -e "s|###RAC_NODE_NAME_PREFIXP###|$RAC_NODE_NAME_PREFIXP|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   sed -i -e "s|###REVERSEIP###|$RAC_PUBLIC_REVERSE_IP|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   sed -i -e "s|###RAC_DNS_SERVER_IP###|$RAC_DNS_SERVER_IP|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   sed -i -e "s|###NAMED_SAMPLE_FILE###|$NAMED_SAMPLE_FILE|g" "${NAMED_CHROOT_ETC_DIR}/$NAMED_CONF_FILE"
}

CopyFiles()
{
   print_message "Copying files to destination dir"
   cp "$SCRIPT_DIR/$NAMED_CONF_FILE" "${NAMED_CHROOT_ETC_DIR}/$NAMED_CONF_FILE"
   cp "$SCRIPT_DIR/$NAMED_SAMPLE_FILE"  "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   cp "$SCRIPT_DIR/$REVERSE_ZONE_FILE" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.rzone"
   cp "$SCRIPT_DIR/$ZONEFILE" "$ZONE_FILE_LOC_2/${DOMAIN_NAME}.zone"
if [ -n "${PRIVATE_DOMAIN_NAME}" ]; then
   cp "$SCRIPT_DIR/$PRIVATE_REVERSE_ZONE_FILE" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.rzone"
   cp "$SCRIPT_DIR/$PRIVATE_ZONEFILE" "$ZONE_FILE_LOC_2/${PRIVATE_DOMAIN_NAME}.zone"
fi
   cp "$SCRIPT_DIR/$NAMED_LOCALHOST_FILE"  "${ZONE_FILE_LOC_2}/"
   cp "/var/named/$NAMED_LOOPBACK_FILE" "${ZONE_FILE_LOC_2}/"
   cp "/var/named/$NAMED_EMPTY_FILE"  "${ZONE_FILE_LOC_2}/"
   chown -R root:named "${NAMED_CHROOT_ETC_DIR}/$NAMED_SAMPLE_FILE"
   chown -R root:named "${NAMED_CHROOT_ETC_DIR}/$NAMED_CONF_FILE"
   chown -R root:named "$ZONE_FILE_LOC_2"
   chown -R named:named "$ZONE_FILE_LOC_2/data"
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
/usr/sbin/named -u named -c "/etc/${NAMED_CONF_FILE}" -t "${NAMED_CHROOT_ROOT_DIR}"
#systemctl start named-chroot

print_message "Checking DNS Server"
if nslookup "$HOSTNAME.$DOMAIN_NAME"; then
    print_message "DNS Server started successfully"
else
    error_exit "DNS Server startup failed"
fi
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

if [ "${SETUP_DNS_CONFIG_FILES}" == 'setup_true' ]; then
   # shellcheck disable=SC2154
   print_message "Starting DNS Server setup" >> "$logfile"
   setEnvVariables
   CopyFiles
   setupZoneFile
   setupReverseZonefile
if [ -n "${PRIVATE_DOMAIN_NAME}" ]; then
   setupPrivateZoneFile
   setupPrivateReverseZonefile
fi
   setupNamed
   setupResolveconf
else
   CopyFiles
fi
startDNSServer

print_message "################################################"
print_message " DNS Server IS READY TO USE!            "
print_message "################################################"
