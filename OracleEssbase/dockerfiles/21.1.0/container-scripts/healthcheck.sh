#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions
checkNonRoot $(basename $0)

# Check if the domain was actually created successfully
domain_marker_success_file=/u01/config/.marker.domain.success
domain_marker_failed_file=/u01/config/.marker.domain.failed

if [ -e ${domain_marker_failed_file} ]; then
  exit 1
fi

if [ ! -e ${domain_marker_success_file} ]; then
  exit 1
fi

export SERVER_NAME=${SERVER_NAME:-AdminServer}

if [ "${SERVER_NAME,,}" == "adminserver" ]; then
  ping_adminserver ${HOSTNAME}
  rc=$?
elif [ "${SERVER_NAME,,}" == "eas_server1" ]; then 
  ping_easserver ${HOSTNAME}
  rc=$?
else 
  ping_managedserver ${HOSTNAME}
  rc=$?
fi

[ $rc -eq 200 ] || exit 1
