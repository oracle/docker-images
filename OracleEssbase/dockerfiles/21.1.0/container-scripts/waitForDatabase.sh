#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)
. ${SCRIPT_DIR}/_essbase-functions

if [ $# -lt 2 ]; then
  echo usage: waitForDatabase.sh username role
  echo password is provided on stdin
  exit 1
fi

DATABASE_USERNAME=$1
DATABASE_ROLE=$2
DATABASE_PASSWORD=$(cat)

if [ "${DATABASE_TYPE}" == "ORACLE" ]; then

  DATABASE_ROLE_VALUE=${DATABASE_ROLE}
  if [ -z "${DATABASE_ROLE_VALUE}" ]; then
    if [ "${DATABASE_USERNAME,,}" == "sys" ] || [ "${DATABASE_USERNAME,,}" == "system" ]; then
      DATABASE_ROLE_VALUE=sysdba
    fi
  fi
fi

DATABASE_WAIT_TIMEOUT=${DATABASE_WAIT_TIMEOUT:-120}
timeout $DATABASE_WAIT_TIMEOUT /bin/bash -e <<EOF
export WLST_PROPERTIES="-Dweblogic.security.SSL.minimumProtocolVersion=TLSv1.2 -Dweblogic.security.SSL.ignoreHostnameVerification=true"
echo "$DATABASE_PASSWORD" | $SCRIPT_DIR/run-wlst.sh $SCRIPT_DIR/wlst/ping_database.py "$DATABASE_TYPE" "$DATABASE_CONNECT_STRING" "$DATABASE_USERNAME" $(novalueIfEmpty $DATABASE_ROLE_VALUE) 5
EOF
rc=$?
if [ $rc -eq 2 ]; then
   log_error "Invalid connection to database"
   exit $rc
elif [ $rc -ne 0 ]; then
   log_error "Timeout while trying to connect to the database"
fi

exit $rc