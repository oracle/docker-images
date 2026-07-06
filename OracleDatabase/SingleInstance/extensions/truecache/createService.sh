#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: Apr, 2024
# Author:paramdeep.saini@oracle.com
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [ $# -ne 5 ] && [ $# -ne 6 ]; then
   echo "Usage : <$0> <PRIMARY_SVCNAME> <TC_SVCNAME> <PRIMARY_PDB_NAME> <TC_CONNECT_STR> <SOURCE_DB> [PASSWORD_OR_WALLET_SOURCE]"
   exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# Reuse the same DBCA resolution for container and remote-host workflows.
. "${SCRIPT_DIR}/dbcaUtils.sh"

PRIMARY_SVCNAME=$1
TC_SVCNAME=$2
PRIMARY_PDB_NAME=$3
TC_CONNECT_STR=$4
SOURCE_DB=$5
PASSWORD_SOURCE=${6:-}

case "${PASSWORD_SOURCE}" in
   ""|NO_PASSWORD|WALLET_PATH:*)
      PASSWORD=""
      ;;
   B64:*)
      PASSWORD=$(printf '%s' "${PASSWORD_SOURCE#B64:}" | base64 -d)
      ;;
   *)
      if [ -x "${PASSWORD_SOURCE}" ]; then
         PASSWORD=$("${PASSWORD_SOURCE}")
      else
         PASSWORD=${PASSWORD_SOURCE}
      fi
      ;;
esac

WALLET_PATH=""
case "${PASSWORD_SOURCE}" in
   WALLET_PATH:*)
      WALLET_PATH="${PASSWORD_SOURCE#WALLET_PATH:}"
      ;;
esac

DBCA_PATH="$(resolve_dbca_path)"

if [ ! -x "${DBCA_PATH}" ]; then
   echo "Unable to find dbca on this host."
   exit 127
fi

DBCA_HELP="$("${DBCA_PATH}" -configureDatabase -help 2>&1)"
TRUECACHE_SERVICE_OPTION="$(resolve_dbca_truecache_option "${DBCA_PATH}" "${DBCA_HELP}" service)"

if [ -z "${TRUECACHE_SERVICE_OPTION}" ]; then
   echo "Unable to determine the DBCA True Cache service option on this host."
   exit 1
fi

if [ -n "${WALLET_PATH}" ] && [ -f "${WALLET_PATH}/ewallet.p12" ]; then
   "${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_SERVICE_OPTION}" -useWalletForDBCredentials true -dbCredentialsWalletLocation "${WALLET_PATH}" -sourceDB "${SOURCE_DB}" -trueCacheConnectString "${TC_CONNECT_STR}" -trueCacheServiceName "${TC_SVCNAME}" -serviceName "${PRIMARY_SVCNAME}" -pdbName "${PRIMARY_PDB_NAME}"
elif [ -n "${PASSWORD}" ]; then
   "${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_SERVICE_OPTION}" -sourceDB "${SOURCE_DB}" -trueCacheConnectString "${TC_CONNECT_STR}" -trueCacheServiceName "${TC_SVCNAME}" -serviceName "${PRIMARY_SVCNAME}" -pdbName "${PRIMARY_PDB_NAME}" <<< "${PASSWORD}"
else
   "${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_SERVICE_OPTION}" -sourceDB "${SOURCE_DB}" -trueCacheConnectString "${TC_CONNECT_STR}" -trueCacheServiceName "${TC_SVCNAME}" -serviceName "${PRIMARY_SVCNAME}" -pdbName "${PRIMARY_PDB_NAME}"
fi
