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

if [ $# -ne 3 ]; then
   echo "Usage : <$0> <BLOBDIR> <SOURCE_DB> <DECRYPT_PWD_FILE>"
   exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# Reuse the same DBCA resolution for container and remote-host workflows.
. "${SCRIPT_DIR}/dbcaUtils.sh"

BLOBDIR=$1
SOURCE_DB=$2
DECRYPT_PWD_FILE=$3

mkdir -p ${BLOBDIR}

PASSWORD=$($DECRYPT_PWD_FILE)
DBCA_PATH="$(resolve_dbca_path)"

if [ ! -x "${DBCA_PATH}" ]; then
   echo "Unable to find dbca on this host."
   exit 127
fi

DBCA_HELP="$("${DBCA_PATH}" -configureDatabase -help 2>&1)"
TRUECACHE_BLOB_OPTION="$(resolve_dbca_truecache_option "${DBCA_PATH}" "${DBCA_HELP}" blob)"

if [ -z "${TRUECACHE_BLOB_OPTION}" ]; then
   echo "Unable to determine the DBCA True Cache blob option on this host."
   exit 1
fi

"${DBCA_PATH}" -silent -configureDatabase "${TRUECACHE_BLOB_OPTION}" -trueCacheBlobLocation "${BLOBDIR}" -sourceDB "${SOURCE_DB}" <<< "${PASSWORD}" > ${BLOBDIR}/..//genBlobdbca.out
/bin/mv ${BLOBDIR}/*.tar.gz ${BLOBDIR}/blobTestData.tar.gz
