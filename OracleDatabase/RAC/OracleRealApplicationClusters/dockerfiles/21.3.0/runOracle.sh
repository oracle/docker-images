#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2021 Oracle and/or its affiliates.
# 
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Runs the Oracle RAC Database inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

###################Capture Process id and source functions.sh###############
source "$SCRIPT_DIR/functions.sh"
###########################sourcing of functions.sh ends here##############

####error_exit function sends a TERM signal, which is caught by trap command and returns exit status 15"####
trap '{ exit 15; }' TERM
###########################trap code ends here##########################

###########################

if [ -f "$logfile" ]; then
mv "$logfile"  "$logfile"."$(date +%Y%m%d-%H%M%S)"
touch "$logfile"
else
touch "$logfile"
fi

chmod 666 "$logfile"
progname=$(basename "$0")
grid_install_status="FALSE"

####################### Constants #################
declare -r FALSE=1
declare -r TRUE=0
##################################################


###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

print_message "Process id of the program : $TOP_ID"
# Check whether container has enough memory
# Github issue #219: Prevent integer overflow,
# only check if memory digits are less than 11 (single GB range and below)
if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes | wc -c` -lt 11 ]; then
   if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` -lt 8589934592  ]; then
      print_message "Error: The container doesn't have enough memory allocated."
      print_message "A database container needs at least 8 GB of memory."
      print_message "You currently only have $((`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`/1024/1024/1024)) GB allocated to the container."
      error_exit "Existing..";
   fi
fi

print_message "#################################################"
print_message " Starting Grid Installation          "
print_message "#################################################"

print_message "Pre-Grid Setup steps are in process"
"$SCRIPT_DIR"/"$SETUPGRIDENV"
stat=$?
if [ $stat -ne 0 ]; then
error_exit "Error has occurred in Grid Setup, Please verify!"
fi

print_message "###################################################"
print_message "Pre-Grid Setup steps completed"
print_message "###################################################"

print_message "Checking if grid is already configured"
if [ -d /etc/oracle ]; then
grid_install_status="TRUE"
if [ -f /etc/oracle/olr.loc ];then
grid_install_status="TRUE"
OLR_FILE=$(cat /etc/oracle/olr.loc | grep olrconfig_loc | awk -F "=" '{ print $2 }')
if [ -f "$OLR_FILE" ]; then
grid_install_status="TRUE"
print_message "Grid is installed on $(hostname). $progname will start the Grid service"
fi
fi
fi

if [ $grid_install_status == "TRUE" ];then
print_message "Setting up Grid Env for Grid Start"
print_message "##########################################################################################"
print_message "Grid is already installed on this container! Grid will be started by default ohasd scripts"
print_message "############################################################################################" 
else
if [ "${OP_TYPE}" == "INSTALL" ]; then
"$SCRIPT_DIR"/"$CONFIGGRID"
stat=$?

if [ $stat -ne 0 ];then
error_exit "Error has occurred in Grid Setup, Please verify!"
fi

print_message "####################################"
print_message "ORACLE RAC DATABASE IS READY TO USE!"
print_message "####################################"
elif [ "${OP_TYPE}" == "ADDNODE" ]; then
"$SCRIPT_DIR"/"$ADDNODE"
stat=$?
if [ $stat -ne 0 ];then
error_exit "Error has occurred in Grid Setup, Please verify!"
fi

print_message "####################################"
print_message "ORACLE RAC DATABASE IS READY TO USE!"
print_message "####################################"
else
print_message "Usage : $progname INSTALL | ADDNODE"
error_exit "You can perform Cluster Install or Add Node"
fi
fi
echo $TRUE
