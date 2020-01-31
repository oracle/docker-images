#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Runs the Oracle Database inside the container
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
local cmd
cmd="$DB_HOME/bin/cmctl shutdown -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN"
eval $cmd
touch /tmp/stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down!"
local cmd
cmd="$DB_HOME/bin/cmctl shutdown -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN"
eval $cmd
touch /tmp/sigterm
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down database!"
local cmd
cmd="$DB_HOME/bin/cmctl shutdown  -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN"
eval $cmd
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

sudo $SCRIPT_DIR/$CONFIG_CMAN_FILE

if [ $? -eq 0 ];then
 print_message "cman started sucessfully"
  echo $TRUE
else 
 error_exit "Cman startup failed!"
fi

tail -f /tmp/orod.log &
childPID=$!
wait $childPID
