#!/bin/bash
# shellcheck disable=SC2034,SC2166,SC2155,SC1090,SC2046,SC2178,SC2207,SC2163,SC2115,SC2173,SC1091,SC1143,SC2164,SC3014
file_name=reset_failed_units.txt
current_time=$(date "+Y.%m.%d-%H.%M.%S")
passed_unit_file_name=passed_units.txt
new_failed_unit_file_name=$file_name.$current_time
systemctl_state=$(systemctl status | awk '/State:/{ print $0 }' | grep -v 'awk /State:/' | awk '{ print $2 }')
if [ "${systemctl_state}" != "running" ]; then
     systemctl reset-failed
     touch "/tmp/$new_failed_unit_file_name"
else
     touch "/tmp/$passed_unit_file_name"
fi