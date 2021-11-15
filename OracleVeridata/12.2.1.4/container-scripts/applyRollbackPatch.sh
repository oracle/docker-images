#!/bin/bash
#
#
# Copyright (c) 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# Author:Arnab Nandi <arnab.x.nandi@oracle.com>
#

echo "Image Patch is: " ${PATCH_FILE}

export ORACLE_HOME=/u01/oracle
export OPATCH_NO_FUSER=true

extract_env() {
   env_value=`awk '{print}' $2 | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo $1=$env_value`
      echo " env_arg: $env_arg"
      export $env_arg
   fi
}

if [ -z ${PATCH_FILE} ]
then
    extract_env APPLY_PATCH_ID /u01/oracle/vdt.env
    extract_env ROLLBACK_PATCH_ID /u01/oracle/vdt.env

    if [ "${APPLY_PATCH_ID}" == "" ]  && [ "${ROLLBACK_PATCH_ID}" == "" ]; then
      # nothing to do
      exit 0 ;
    fi

    if [ "${APPLY_PATCH_ID}" != "" ]
    then
      APPLY_PATCH_FILE="p${APPLY_PATCH_ID}*.zip"
    fi
else
    APPLY_PATCH_FILE="${PATCH_FILE}"
fi

if [ -z ${SERVER_START} ]
then
  export SERVER_START="True"
fi

APPLY_PATCH_DIR="patch_top"

if [ "${APPLY_PATCH_ID}" != "" ] || [ "${PATCH_FILE}" != "" ];then
    echo "APPLY_PATCH_FILE:$APPLY_PATCH_FILE"
    mkdir ${ORACLE_HOME}/${APPLY_PATCH_DIR}
    cd ${ORACLE_HOME}/${APPLY_PATCH_DIR}
    ${JAVA_HOME}/bin/jar xf ${ORACLE_HOME}/${APPLY_PATCH_FILE}

    ${ORACLE_HOME}/OPatch/opatch lspatches -jre ${JAVA_HOME}/jre | grep -Eo '[0-9]{8,10}' >> rollback.txt
    ROLLBACK_PATCH_ID="$(grep -Eo '[0-9]{8,10}' rollback.txt)"
    echo "ROLLBACK_PATCH_ID:${ROLLBACK_PATCH_ID}"
else
exit 0;
fi

if [ "${SERVER_START}" == "True" ]
then
    ${DOMAIN_HOME}/veridata/bin/veridataServer.sh stop
    echo "Waiting for OGG Veridata Server to be down"
    sleep 15
fi

if [ "${ROLLBACK_PATCH_ID}" == "" ]
then
    echo "patch_top:${ORACLE_HOME}/${APPLY_PATCH_DIR}"
    ls -ltr ${ORACLE_HOME}/${APPLY_PATCH_DIR}
    ${ORACLE_HOME}/OPatch/opatch napply -silent -jre ${JAVA_HOME}/jre ${ORACLE_HOME}/${APPLY_PATCH_DIR}
else
    echo "ROLLBACK PATCH ID:${ROLLBACK_PATCH_ID}"

    ${ORACLE_HOME}/OPatch/opatch rollback -id  ${ROLLBACK_PATCH_ID} -silent -jre ${JAVA_HOME}/jre
    if [ "${APPLY_PATCH_DIR}" != "" ]
    then
      ${ORACLE_HOME}/OPatch/opatch napply -silent -jre ${JAVA_HOME}/jre ${ORACLE_HOME}/${APPLY_PATCH_FILE} ${ORACLE_HOME}/${APPLY_PATCH_DIR}
    fi
fi

cd ${ORACLE_HOME}
rm -rf ${ORACLE_HOME}/patch_top






