#!/bin/bash
#############################
# Copyright 2023, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
############################

current_time=$(date "+Y.%m.%d-%H.%M.%S")
new_failed_unit_file_name="failed_units_${current_time}"
systemctl_state=$(systemctl status | awk '/State:/{ print $0 }' | grep -v 'awk /State:/' | awk '{ print $2 }')

if [ "${systemctl_state}" != "running" ]; then
 systemctl reset-failed
  touch /tmp/"$new_failed_unit_file_name"
fi

