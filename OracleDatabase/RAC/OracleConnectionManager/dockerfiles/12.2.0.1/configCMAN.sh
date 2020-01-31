#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Configure and setup CMAN 
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source /tmp/envfile

source $SCRIPT_DIR/functions.sh 

####################### Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -r ETCHOSTS="/etc/hosts"
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

if [ -z "${PORT}" ]; then
   print_message  "PORT is not defined. Setting PORT to '1521'"
   PORT="1521"
 else
 print_message "PORT is defined to $PORT"
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
  print_message "SCAN_NAME set to the empty string"
else
  print_message "SCAN_NAME name is ${SCAN_NAME}"
fi

if [ -z ${SCAN_IP} ]; then
   print_message "SCAN_IP set to the empty string"
else
  print_message "SCAN_IP name is ${SCAN_IP}"
fi

}

####################################### ETC Host Function #############################################################

SetupEtcHosts()
{
local stat=3
local HOST_LINE

echo -e "127.0.0.1\tlocalhost.localdomain\tlocalhost" > /etc/hosts
echo -e "$PUBLIC_IP\t$PUBLIC_HOSTNAME.$DOMAIN\t$PUBLIC_HOSTNAME" >> /etc/hosts
echo -e "$SCAN_IP\t$SCAN_NAME.$DOMAIN\t$SCAN_NAME" >> /etc/hosts
}

######### Grid setup Function###########################
cman_file ()
{

cp $SCRIPT_DIR/$CMANORA $logdir/$CMANORA

sed -i -e "s|###CMAN_HOSTNAME###|$PUBLIC_HOSTNAME|g" $logdir/$CMANORA
sed -i -e "s|###DOMAIN###|$DOMAIN|g" $logdir/$CMANORA
sed -i -e "s|###DB_HOME###|$DB_HOME|g" $logdir/$CMANORA
sed -i -e "s|###PORT###|$PORT|g" $logdir/$CMANORA
}

copycmanora ()
{
cp $logdir/$CMANORA $DB_HOME/network/admin/
chown -R oracle:oinstall $DB_HOME/network/admin/
rm -f $logdir/$CMANORA
}

start_cman ()
{
local cmd
cmd="su - oracle -c \"$DB_HOME/bin/cmctl startup -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN\""
eval $cmd
}

stop_cman ()
{
local cmd
cmd="su - oracle -c \"$DB_HOME/bin/cmctl shutdown -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN\""
eval $cmd
}

status_cman ()
{
local cmd
cmd="su - oracle -c \"$DB_HOME/bin/cmctl show service -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN\""
eval $cmd

if [ $? -eq 0 ];then
print_message "cman started sucessfully"
else
error_exit "Cman startup failed"
fi

}


###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

########
#clear_files
SetupEtcHosts
all_check

####### CMAN Setup ##########
print_message "Generating CMAN file"
cman_file
print_message "Copying CMAN file to $DB_HOME/network/admin"
copycmanora
print_message "Starting CMAN"
start_cman
print_message "Checking CMAN Status"
status_cman
print_message "################################################"
print_message " CONNECTION MANAGER IS READY TO USE!            "
print_message "################################################"
