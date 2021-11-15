#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2017,2021 Oracle and/or its affiliates.
#
# Since: January, 2017
# Author: sanjay.singh@oracle.com,  paramdeep.saini@oracle.com
# Description:
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
env > /tmp/envfile

chmod 755 /tmp/envfile 
source /tmp/envfile

source $SCRIPT_DIR/functions.sh

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
sudo kill -9 `ps -ef | grep named`
touch /tmp/stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down!"
sudo kill -9 `ps -ef | grep named`
touch /tmp/sigterm
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down database!"
local cmd
sudo kill -9 `ps -ef | grep named`
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

############ Removing /tmp/orod.log #####
print_message "Creating $logfile"
chmod 666  $logfile
sudo $SCRIPT_DIR/$CONFIG_DNS_SERVER_FILE

if [ $? -eq 0 ];then
 print_message "DNS Server Started Successfully"
  echo $TRUE
else 
 error_exit "DNS Server startup failed!"
fi

tail -f /tmp/orod.log &
childPID=$!
wait $childPID
