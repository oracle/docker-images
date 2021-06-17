#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

export OPATCH_NO_FUSER=TRUE

if [ ! -z "$(ls ${SCRIPT_DIR}/p*.zip 2>/dev/null)" ]; then
  cd ${SCRIPT_DIR}
  echo -e "\nBelow patches present in patches directory. Applying these patches:"
  ls p*.zip
  echo -e ""
  for filename in $(ls p*.zip); do 
    echo "Extracting patch: ${filename}"
    ${JAVA_HOME}/bin/jar xf ${filename}
  done
  
  rm -f ${SCRIPT_DIR}/p*.zip
  if [ -e ${SCRIPT_DIR}/6880880 ]; then
    ${JAVA_HOME}/bin/java -jar ${SCRIPT_DIR}/6880880/opatch_generic.jar -silent oracle_home=${ORACLE_HOME}
    rm -rf ${SCRIPT_DIR}/6880880
  fi
  cd /u01
  ${ORACLE_HOME}/OPatch/opatch napply -silent -oh $ORACLE_HOME -jre ${JAVA_HOME} -invPtrLoc /u01/oraInst.loc -phBaseDir ${SCRIPT_DIR}
  ${ORACLE_HOME}/OPatch/opatch util cleanup -silent
  rm -rf ${ORACLE_HOME}/cfgtoollogs
  rm -rf ${ORACLE_HOME}/.inventory/logs
  rm -rf ${ORACLE_HOME}/.patch_storage
  echo -e "\nPatches applied in oracle home are:"
  ${ORACLE_HOME}/OPatch/opatch lspatches
else
  echo -e "\nNo patches present in patches directory. Skipping patch application."
fi
