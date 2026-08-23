#!/bin/bash
#
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
############################
# Description: Runs  NFS server inside the container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ -f /etc/storage_env_vars ]; then
# shellcheck disable=SC1091
	source /etc/storage_env_vars
fi

logfile="/tmp/storage_setup.log"

touch $logfile
chmod 666 $logfile
# shellcheck disable=SC2034,SC2086
progname="$(basename $0)"

####################### Constants #################
# shellcheck disable=SC2034
declare -r FALSE=1
# shellcheck disable=SC2034
declare -r TRUE=0
export REQUIRED_SPACE_GB=55
export ORADATA=/oradata
export INSTALL_COMPLETED_FILE="/workdir/installcomplete"
export FILE_COUNT=0
##################################################

check_space ()
{
	local REQUIRED_SPACE_GB=$1
    # shellcheck disable=SC2006
	AVAILABLE_SPACE_GB=`df -B 1G $ORADATA | tail -n 1 | awk '{print $4}'`
	if [ ! -f ${INSTALL_COMPLETED_FILE} ] ;then
	# shellcheck disable=SC2086
		if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
		# shellcheck disable=SC2006
			  script_name=`basename "$0"`
			    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tee -a $logfile
			      echo "$script_name: ERROR - There is not enough space available in the docker container under $ORADATA." | tee -a $logfile
			        echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB , but only $AVAILABLE_SPACE_GB available." | tee -a $logfile
				  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tee -a $logfile
				    exit 1;
			    else
				     echo " Space check passed : $ORADATA has available space $AVAILABLE_SPACE_GB and ASM storage set to $REQUIRED_SPACE_GB" | tee -a $logfile
			     fi;
		     fi;
}
####################################### ETC Host Function #############################################################

setupEtcResolvConf()
{
local stat=3
# shellcheck disable=SC2154
if [ "$action" == "" ]; then
# shellcheck disable=SC2236
   if [ ! -z "${DNS_SERVER}" ] ; then
     sudo sh -c "echo \"search  ${DOMAIN}\"  > /etc/resolv.conf"	   
     sudo sh -c "echo \"nameserver ${DNS_SERVER}\"  >> /etc/resolv.conf"
  fi
fi

}

SetupEtcHosts()
{
# shellcheck disable=SC2034
local stat=3
# shellcheck disable=SC2034
local HOST_LINE
if [ "$action" == "" ]; then
# shellcheck disable=SC2236
 if [ ! -z "${HOSTFILE}" ]; then 
   if [ -f "${HOSTFILE}" ]; then
     sudo sh -c "cat \"${HOSTFILE}\" > /etc/hosts"
   fi
 else	 
  sudo sh -c "echo -e \"127.0.0.1\tlocalhost.localdomain\tlocalhost\" > /etc/hosts"
  sudo sh -c "echo -e \"$PUBLIC_IP\t$PUBLIC_HOSTNAME.$DOMAIN\t$PUBLIC_HOSTNAME\" >> /etc/hosts"
 fi
fi

}



	     ###################################
	     # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
	     ############# MAIN ################
	     # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
	     ###################################

	     if [ ! -d "$ORADATA" ] ;then
		     echo "$ORADATA dir doesn't exist! exiting" | tee -a $logfile
		     exit 1
	     fi
         # shellcheck disable=SC2086
	     if [  -z $ASM_STORAGE_SIZE_GB ] ;then
		     echo "ASM_STORAGE_SIZE env variable is not defined! Assigning 50GB default" | tee -a $logfile
		     ASM_STORAGE_SIZE_GB=50
	     else
		     echo "ASM STORAGE SIZE set to : $ASM_STORAGE_SIZE_GB" | tee -a $logfile
	     fi
         ####### Populating resolv.conf and /etc/hosts ###
		 setupEtcResolvConf
         SetupEtcHosts
         ####################
	     echo "Oracle user will be the owner for /oradata" | tee -a $logfile
	     sudo chown -R oracle:oinstall /oradata

	     echo "Checking Space" | tee -a $logfile
	     check_space $ASM_STORAGE_SIZE_GB
		 # shellcheck disable=SC2004
	     ASM_DISKS_SIZE=$(($ASM_STORAGE_SIZE_GB/5))
	     count=1;
	     while [ $count -le 5 ];
	     do
		     echo "Creating ASM Disks $ORADATA/asm_disk0$count.img of size $ASM_DISKS_SIZE" | tee -a $logfile

		     if [ ! -f $ORADATA/asm_disk0$count.img ];then
			     dd if=/dev/zero of=$ORADATA/asm_disk0$count.img bs=1G count=$ASM_DISKS_SIZE
			     chown oracle:oinstall $ORADATA/asm_disk0$count.img
		     else
			     echo "$ORADATA/asm_disk0$count.img file already exist! Skipping file creation" | tee -a $logfile
		     fi
             # shellcheck disable=SC2004
		     count=$(($count+1))
	     done
         # shellcheck disable=SC2012
	     FILE_COUNT=$(ls $ORADATA/asm_disk0* | wc -l)
         # shellcheck disable=SC2086
	     if [ ${FILE_COUNT} -ge 5 ];then
		     echo "Touching ${INSTALL_COMPLETED_FILE}" | tee -a $logfile
		     touch ${INSTALL_COMPLETED_FILE}
	     fi

	     echo "#################################################" | tee -a $logfile
	     echo " Starting NFS Server Setup                       " | tee -a $logfile
	     echo "#################################################" | tee -a $logfile


	     echo "Starting Nfs Server" | tee -a $logfile
	     systemctl start  nfs-utils.service | tee -a $logfile
	     systemctl restart rpcbind.service | tee -a $logfile
	     systemctl start  nfs-server.service | tee -a $logfile

	     echo "Checking Nfs Service" | tee -a $logfile
	     systemctl status nfs-utils.service | tee -a $logfile

	     echo "Checking rpc bind service"
	     systemctl status rpcbind.service | tee -a $logfile

	     echo "Setting up /etc/exports"
		 # shellcheck disable=SC2086,SC2002
	     cat $SCRIPT_DIR/$EXPORTFILE | tee -a /etc/exports

	     echo "Exporting File System"
	     sudo /usr/sbin/exportfs -r | tee -a $logfile

	     echo "Checking exported mountpoints" | tee -a $logfile
	     showmount -e | tee -a $logfile

	     echo "#################################################" | tee -a $logfile
	     echo " Setup Completed                                 " | tee -a $logfile
	     echo "#################################################" | tee -a $logfile
