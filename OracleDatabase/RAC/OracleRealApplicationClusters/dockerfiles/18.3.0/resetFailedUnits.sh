#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Reset failed units
# ------------------------------------------------------------

failed_unit_file_name=reset_failed_units.txt
current_time=$(date "+Y.%m.%d-%H.%M.%S")
passed_unit_file_name=passed_units.txt

new_failed_unit_file_name=$file_name.$current_time
systemctl_state=$(systemctl status | awk '/State:/{ print $0 }' | grep -v 'awk /State:/' | awk '{ print $2 }')

if [ "${systemctl_state}" != "running" ]; then
 systemctl reset-failed
  touch /tmp/$new_failed_unit_file_name
else
  touch /tmp/$passed_unit_file_name
fi
