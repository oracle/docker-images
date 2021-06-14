#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions

# Check if the domain was actually created successfully
domain_marker_success_file=/u01/config/.marker.domain.success
domain_marker_failed_file=/u01/config/.marker.domain.failed

if [ -e ${domain_marker_failed_file} ]; then
  exit
fi

if [ ! -e ${domain_marker_success_file} ]; then
  exit
fi

ADMIN_USERNAME=$1

# Read credentials from stdin
read -r ADMIN_PASSWORD

if [ "${SERVER_NAME}" == "eas_server1" ]; then
  SERVER_URL=$(calculateEASServerT3Url ${HOSTNAME})
else
  SERVER_URL=$(calculateManagedServerT3Url ${HOSTNAME})
fi

echo ${ADMIN_PASSWORD} | ${SCRIPT_DIR}/run-wlst.sh ${SCRIPT_DIR}/wlst/stop_server.py ${SERVER_URL} ${ADMIN_USERNAME}
