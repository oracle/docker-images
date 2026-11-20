#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
# Description: Reconcile the database LOCAL_LISTENER with the current pod IP.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

set -u

ORACLE_HOME="${ORACLE_HOME:-/opt/oracle/product/26ai/dbhome_1}"
export PATH="${ORACLE_HOME}/bin:${PATH}"

is_ipv4() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

listener_host="${LOCAL_LISTENER_HOST:-}"
if ! is_ipv4 "${listener_host}"; then
  listener_host="$(hostname -i 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/) { print $i; exit }}')"
fi
if ! is_ipv4 "${listener_host}" && is_ipv4 "${ORACLE_HOSTNAME:-}"; then
  listener_host="${ORACLE_HOSTNAME}"
fi

if ! is_ipv4 "${listener_host}"; then
  echo "WARNING: unable to determine an IPv4 address for LOCAL_LISTENER registration"
  exit 0
fi

if ! sqlplus -s / as sysdba <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SYSTEM SET local_listener='(ADDRESS=(PROTOCOL=TCP)(HOST=${listener_host})(PORT=1521))' SCOPE=BOTH;
ALTER SYSTEM REGISTER;
EXIT;
SQL
then
  echo "WARNING: LOCAL_LISTENER registration failed for ${listener_host}; startup will continue"
  exit 0
fi

echo "INFO: registered database services with LOCAL_LISTENER ${listener_host}:1521"
