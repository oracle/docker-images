#!/bin/bash
#
#############################
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

source "$SCRIPT_DIR/functions.sh"

shutdown_cman()
{
   if [ -z "${DB_HOME}" ] || [ -z "${PUBLIC_HOSTNAME}" ] || [ -z "${DOMAIN}" ]; then
      print_message "Skipping CMAN shutdown because required environment is not fully set"
      return 0
   fi

   "$DB_HOME/bin/cmctl" shutdown -c "CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}"
}

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   shutdown_cman
   touch /tmp/stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down!"
   shutdown_cman
   touch /tmp/sigterm
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

############ Initializing CMAN startup logfile #####
print_message "Creating $logfile"
init_logfile
chmod 666 "$logfile" 2>/dev/null || true

"$SCRIPT_DIR/$CONFIG_CMAN_FILE"

if [ $? -eq 0 ];then
 print_message "cman started sucessfully"
  echo $TRUE
else 
 error_exit "Cman startup failed!"
fi

tail -f "$logfile" &
childPID=$!
wait $childPID
