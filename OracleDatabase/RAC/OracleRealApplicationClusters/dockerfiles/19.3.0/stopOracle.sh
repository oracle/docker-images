#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Stop Oracle RAC DB and Deconfigure the cluster.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

if [ -f /etc/rac_env_vars ]; then
source /etc/rac_env_vars
fi

source $SCRIPT_DIR/functions.sh
touch $logfile
chmod 666 /tmp/orod.log
progname="$(basename $0)"

########### Stop Svc ############
stop_svc () {
 print_message "Stopping container and performing Grid stop."
 $GRID_HOME/bin/crsctl stop crs -f
}

########### Deconfig Node from the cluster ############
deconfig_cluster () {
   print_message "received, shutting down database!"
   node_count=$($GRID_HOME/bin/olsnodes -a | awk '{ print $1 }' | wc -l)
  if [ $node_count -gt 1 ]; then
   $GRID_HOME/crs/install/rootcrs.sh -deconfig -force
  elif [ $node_count -eq 1 ]; then
    $GRID_HOME/crs/install/rootcrs.sh -deconfig -force -last
  else
   print_message "No need to deinstall cluster as it is not configured"
  fi

 print_message " Removing entries from /etc/hosts"
   sed -i '/$PUBLIC_HOSTNAME/d' /etc/hosts
   sed -i '/$PRIVATE_HOSTNAME/d' /etc/hosts
   sed -i '/$VIP_HOSTNAME/d' /etc/hosts
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

if [ "${STOP_TYPE}" == "DECONFIGURE" ]; then
deconfig_cluster
else
stop_svc
fi
