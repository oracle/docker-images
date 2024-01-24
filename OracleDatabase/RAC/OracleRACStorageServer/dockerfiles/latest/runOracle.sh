#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2014-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
# Description: Runs  NFS server inside the container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ -f /etc/storage_env_vars ]; then
# shellcheck disable=SC1091
  source /etc/storage_env_vars
else
  echo "Warning: /etc/storage_env_vars not found. Some environment variables may not be set."
fi

logfile="/tmp/storage_setup.log"

touch $logfile
chmod 666 $logfile

####################### Constants #################
export REQUIRED_SPACE_GB=55
export ORADATA=/oradata
export INSTALL_COMPLETED_FILE="/workdir/installcomplete"
export FILE_COUNT=0
##################################################

check_space ()
{
	local REQUIRED_SPACE_GB=$1

	AVAILABLE_SPACE_GB=$(df -B 1G "$ORADATA" | tail -n 1 | awk '{print $4}')
	if [ ! -f ${INSTALL_COMPLETED_FILE} ] ;then
		if [ "$AVAILABLE_SPACE_GB" -lt "$REQUIRED_SPACE_GB" ]; then
			  script_name=$(basename "$0")
			    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tee -a $logfile
			      echo "$script_name: ERROR - There is not enough space available in the docker container under $ORADATA." | tee -a $logfile
			        echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB , but only $AVAILABLE_SPACE_GB available." | tee -a $logfile
				  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tee -a $logfile
				    exit 1;
			    else
				     echo " Space check passed : $ORADATA has avilable space $AVAILABLE_SPACE_GB and ASM storage set to $REQUIRED_SPACE_GB" | tee -a $logfile
			     fi;
		     fi;
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

	     if [ -z "$ASM_STORAGE_SIZE_GB" ]; then
		     echo "ASM_STORAGE_SIZE env variable is not defined! Assigning 50GB default" | tee -a $logfile
		     ASM_STORAGE_SIZE_GB=50
	     else
		     echo "ASM STORAGE SIZE set to : $ASM_STORAGE_SIZE_GB" | tee -a $logfile
	     fi

	     echo "Oracle user will be the owner for /oradata" | tee -a $logfile
	     sudo chown -R oracle:oinstall /oradata

	     echo "Checking Space" | tee -a $logfile
	     check_space "$ASM_STORAGE_SIZE_GB"
	     ASM_DISKS_SIZE=$((ASM_STORAGE_SIZE_GB / 5))
	     count=$((count + 1))
	     while [ $count -le 5 ];
	     do
		     echo "Creating ASM Disks $ORADATA/asm_disk0$count.img of size $ASM_DISKS_SIZE" | tee -a $logfile

		     if [ ! -f $ORADATA/asm_disk0$count.img ];then
			     dd if=/dev/zero of=$ORADATA/asm_disk0$count.img bs=1G count=$ASM_DISKS_SIZE
			     chown oracle:oinstall $ORADATA/asm_disk0$count.img
		     else
			     echo "$ORADATA/asm_disk0$count.img file already exist! Skipping file creation" | tee -a $logfile
		     fi

		     count=$((count + 1))
	     done

	     FILE_COUNT=$(find "$ORADATA" -maxdepth 1 -type f -name 'asm_disk0*' | wc -l)

	     if [ "${FILE_COUNT}" -ge 5 ]; then
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
 	     tee -a /etc/exports < "$SCRIPT_DIR/$EXPORTFILE"

	     echo "Exporting File System"
	     sudo /usr/sbin/exportfs -r | tee -a $logfile

	     echo "Checking exported mountpoints" | tee -a $logfile
	     showmount -e | tee -a $logfile

	     echo "#################################################" | tee -a $logfile
	     echo " Setup Completed                                 " | tee -a $logfile
	     echo "#################################################" | tee -a $logfile
