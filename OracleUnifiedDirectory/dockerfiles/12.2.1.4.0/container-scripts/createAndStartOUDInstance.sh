#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# Script to create OUD instance based on the passed parameters.
# 

# Variables for this script to work
source ${SCRIPT_DIR}/setEnvVars.sh
source ${SCRIPT_DIR}/common_functions.sh

########### SIGTERM handler ############
function _term() {
   echo "[$(date)] - Stopping container."
   echo "[$(date)] - SIGTERM received, shutting down the server!"
   $OUD_INST_HOME/bin/stop-ds
}

########### SIGKILL handler ############
function _kill() {
   echo "[$(date)] - SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

# 
updateJavaProps() {
  echo "" >> ${OUD_INST_HOME}/config/java.properties
  #	Disabling Enpoint Identification for selected CLIs to allow connecting to OUD Instance with any hostname
  echo "dsconfig.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "dsreplication.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "uninstall.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "status.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "import-ldif.online.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "manage-suffix.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "ldapmodify.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "ldapsearch.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  echo "start-ds.java-args=-server -Xms256m -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${OUD_INST_HOME}/config/java.properties
  ${OUD_INST_HOME}/bin/dsjavaproperties
}

printEnvVars() {
	echo "[$(date)] - Environment Variables which would influence OUD Instance setup and configuration"
    echo "instanceType [${instanceType}]"
    echo "hostname [${hostname}]"
    echo "ldapPort [${ldapPort}]"
    echo "ldapsPort [${ldapsPort}]"
    echo "rootUserDN [${rootUserDN}]"
    echo "baseDN [${baseDN}]"
    echo "adminConnectorPort [${adminConnectorPort}]"
    echo "httpAdminConnectorPort [${httpAdminConnectorPort}]"
    echo "httpPort [${httpPort}]"
    echo "httpsPort [${httpsPort}]"
    echo "sampleData [${sampleData}]"
    echo "integration [${integration}]"
    echo "replicationPort [${replicationPort}]"
    echo "sourceHost [${sourceHost}]"
    echo "initializeFromHost [${initializeFromHost}]"
    echo "sourceAdminConnectorPort [${sourceAdminConnectorPort}]"
    echo "sourceReplicationPort [${sourceReplicationPort}]"
    echo "adminUID [${adminUID}]"
    echo "bindDN1 [${bindDN1}]"
    echo "bindDN2 [${bindDN2}]"
    echo "serverTuning [${serverTuning}]"
    echo "offlineToolsTuning [${offlineToolsTuning}]"
    echo "generateSelfSignedCertificate [${generateSelfSignedCertificate}]"
    echo "usePkcs11Keystore [${usePkcs11Keystore}]"
    echo "useJavaKeystore [${useJavaKeystore}]"
    echo "useJCEKS [${useJCEKS}]"
    echo "usePkcs12keyStore [${usePkcs12keyStore}]"
    echo "keyStorePasswordFile [${keyStorePasswordFile}]"
    echo "certNickname [${certNickname}]"
    echo "keyPasswordFile [${keyPasswordFile}]"
    echo "enableStartTLS [${enableStartTLS}]"
    echo "jmxPort [${jmxPort}]"
    echo "eusPasswordScheme [${eusPasswordScheme}]"
	echo "sleepBeforeConfig [${sleepBeforeConfig}]"
    echo "restartAfterDstune [${restartAfterDstune}]"
    echo "restartAfterDsconfig [${restartAfterDsconfig}]"
    echo "restartAfterPostDsreplDsconfig [${restartAfterPostDsreplDsconfig}]"
    echo "restartAfterDsreplication [${restartAfterDsreplication}]"
    echo "restartAfterJavaSecurityFile [${restartAfterJavaSecurityFile}]"
    echo "restartAfterSchemaConfig [${restartAfterSchemaConfig}]"
    echo "restartAfterRebuildIndex [${restartAfterRebuildIndex}]"
    echo "restartAfterManageSuffix [${restartAfterManageSuffix}]"
    echo "restartAfterImportLdif [${restartAfterImportLdif}]"
    echo "ignoreErrorDstune [${ignoreErrorDstune}]"
    echo "ignoreErrorDsconfig [${ignoreErrorDsconfig}]"
    echo "ignoreErrorPostDsreplDsconfig [${ignoreErrorPostDsreplDsconfig}]"
    echo "ignoreErrorDsreplication [${ignoreErrorDsreplication}]"
    echo "ignoreErrorSchemaConfig [${ignoreErrorSchemaConfig}]"
    echo "ignoreErrorRebuildIndex [${ignoreErrorRebuildIndex}]"
    echo "ignoreErrorManageSuffix [${ignoreErrorManageSuffix}]"
    echo "ignoreErrorImportLdif [${ignoreErrorImportLdif}]"
    echo "ignoreErrorExecCmd [${ignoreErrorExecCmd}]"

	isRootUserPasswordEmpty="SET"
	if [ -z "${rootUserPassword}" ]
	then
	  isRootUserPasswordEmpty="Empty or Unset"
	fi
    echo "rootUserPassword [${isRootUserPasswordEmpty}]"
	isAdminPasswordEmpty="SET"
	if [ -z "${adminPassword}" ]
	then
	  isAdminPasswordEmpty="Empty or Unset"
	fi
    echo "adminPassword [${isAdminPasswordEmpty}]"
	isBindPassword1Empty="SET"
	if [ -z "${bindPassword1}" ]
	then
	  isBindPassword1Empty="Empty or Unset"
	fi
    echo "bindPassword1 [${isBindPassword1Empty}]"
	isBindPassword2Empty="SET"
	if [ -z "${bindPassword2}" ]
	then
	  isBindPassword2Empty="Empty or Unset"
	fi
    echo "bindPassword2 [${isBindPassword2Empty}]"
	printLdifFileParams
    printDstuneParams
    printSchemaConfigParams
	printDsconfigBatchFileParams
    printDsConfigParams
    printDsreplicationParams
    printPost_dsreplication_dsconfigParams
    printRebuildIndexParams
    printManageSuffixParams
    printImportLdifParams
    printExecCmdParams
}

# Functions to Create and Delete Pwd Files
createPwdFiles() {
  echo ${rootUserPassword} > ${rootPwdFile}
  echo ${adminPassword} > ${adminPwdFile}
  echo ${bindPassword1} > ${bindPwdFile1}
  echo ${bindPassword2} > ${bindPwdFile2}
}

deletePwdFiles() {
  rm -f ${rootPwdFile}
  rm -f ${adminPwdFile}
  rm -f ${bindPwdFile1}
  rm -f ${bindPwdFile2}
}

############ OUD Instance Configuration ############

checkCommonInstance_Params() {
  echo "[$(date)] - Checking Parameters before Creating OUD Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  if [ -z "${OUD_INSTANCE_NAME}" -o -z "${rootUserDN}" -o -z "${rootUserPassword}" ]
  then
	echo "[$(date)] - One of the required environment variable is not set"
    echo "[$(date)] - OUD_INSTANCE_NAME [${OUD_INSTANCE_NAME}]"
    echo "[$(date)] - rootUserDN [${rootUserDN}]"
	isRootUserPasswordEmpty="SET"
	if [ -z "${rootUserPassword}" ]
	then
	  isRootUserPasswordEmpty="Empty or Unset"
	fi
    echo "[$(date)] - rootUserPassword [${isRootUserPasswordEmpty}]"
	deletePwdFiles
	exit 1
  fi
  # All common port numeric valdations are added #
  export enableStartTLS_Param=""
  export jmxPort_Param=""
  export ldapPort_Param=""
  export ldapsPort_Param=""
  export httpPort_Param=""
  export httpsPort_Param=""
  export adminConnectorPort_Param=""
  export httpAdminConnectorPort_Param=""
  if [[ "${jmxPort}" =~ ^[0-9]+$ ]]
  then
    export jmxPort_Param="--jmxPort ${jmxPort}"
  fi
  if [[ "${ldapPort}" =~ ^[0-9]+$ ]]
  then
    export ldapPort_Param="--ldapPort ${ldapPort}"
  fi
  if [[ "${ldapsPort}" =~ ^[0-9]+$ ]]
  then
    export ldapsPort_Param="--ldapsPort ${ldapsPort}"
  fi
  if [[ "${httpPort}" =~ ^[0-9]+$ ]]
  then
    export httpPort_Param="--httpPort ${httpPort}"
  fi
  if [[ "${httpsPort}" =~ ^[0-9]+$ ]]
  then
    export httpsPort_Param="--httpsPort ${httpsPort}"
  fi
  if [[ "${adminConnectorPort}" =~ ^[0-9]+$ ]]
  then
    export adminConnectorPort_Param="--adminConnectorPort ${adminConnectorPort}"
  fi
  if [[ "${httpAdminConnectorPort}" =~ ^[0-9]+$ ]]
  then
    export httpAdminConnectorPort_Param="--httpAdminConnectorPort ${httpAdminConnectorPort}"
  fi
  if [ ! -z "${eusPasswordScheme}" ]
  then
    export eusPasswordScheme_Param="--eusPasswordScheme ${eusPasswordScheme}"
  fi

  ## function call to check certificate Params####
  checkCertificate_Params
}

########### function for Data Initilization of Data through LDIF files ########
checkDataLdif() {

  export dataParam=""
  if [ ! -z "${ldifFile_1}" -a -f "${ldifFile_1}" ]
  then
    for ldifFile_Param in "${ldifFile_1}" "${ldifFile_2}" "${ldifFile_3}" "${ldifFile_4}" "${ldifFile_5}" "${ldifFile_6}" "${ldifFile_7}" "${ldifFile_8}" "${ldifFile_9}" "${ldifFile_10}" "${ldifFile_11}" "${ldifFile_12}" "${ldifFile_13}" "${ldifFile_14}" "${ldifFile_15}" "${ldifFile_16}" "${ldifFile_17}" "${ldifFile_18}" "${ldifFile_19}" "${ldifFile_20}" "${ldifFile_21}" "${ldifFile_22}" "${ldifFile_23}" "${ldifFile_24}" "${ldifFile_25}" "${ldifFile_26}" "${ldifFile_27}" "${ldifFile_28}" "${ldifFile_29}" "${ldifFile_30}" "${ldifFile_31}" "${ldifFile_32}" "${ldifFile_33}" "${ldifFile_34}" "${ldifFile_35}" "${ldifFile_36}" "${ldifFile_37}" "${ldifFile_38}" "${ldifFile_39}" "${ldifFile_40}" "${ldifFile_41}" "${ldifFile_42}" "${ldifFile_43}" "${ldifFile_44}" "${ldifFile_45}" "${ldifFile_46}" "${ldifFile_47}" "${ldifFile_48}" "${ldifFile_49}" "${ldifFile_50}"
    do
      if [ -f "${ldifFile_Param}" ]
      then
        dataParam+=" --ldifFile ${ldifFile_Param}"
      fi
    done
  fi
  if [ -z "${dataParam}" ]
  then
    export dataParam="--addBaseEntry"
    if [ -z ${sampleData} ]; then
      echo "[$(date)] - sampleData is not set. --addBaseEntry parameter would be added for ${baseDN}"
      export dataParam="--addBaseEntry"
    elif [ "${sampleData}" = "0" ]; then
      echo "[$(date)] - sampleData is set 0 (zero). --addBaseEntry parameter would be added for ${baseDN}"
      export dataParam="--addBaseEntry"
    elif [[ "${sampleData}" =~ ^[0-9]+$ ]]; then
      echo "[$(date)] - sampleData is set to a number. OUD instance would be created with $sampleData sample entries"
      export dataParam="--sampleData $sampleData"
    else
      echo "[$(date)] - sampleData is not having numeric value set. --addBaseEntry parameter would be added for ${baseDN}"
      export dataParam="--addBaseEntry"
    fi
  fi
  export dataParam=${dataParam}
}

########### function for Certificate Parameter check #############
checkCertificate_Params() {
  echo "[$(date)] - Checking Certificate Parameters "
  export generateSelfSignedCertificate_Param=""
  export usePkcs11Keystore_Param=""
  export enableStartTLS_Param=""
  export useJCEKS_Param=""
  export usePkcs12keyStore_Param=""
  export keyStorePasswordFile_Param=""
  export certNickname_Param=""
  export keyStorePasswordFile_Param=""
  if [ "${generateSelfSignedCertificate}" == "true" ]
  then
    export generateSelfSignedCertificate_Param="--generateSelfSignedCertificate"
  fi
  if [ "${usePkcs11Keystore}" == "true" ]
  then
    export usePkcs11Keystore_Param="--usePkcs11Keystore"
  fi
  if [ -f "${useJavaKeystore}" ]
  then
    export useJavaKeystore_Param="--useJavaKeystore ${useJavaKeystore}"
  fi
  if [ -f "${useJCEKS}" ]
  then
    export useJCEKS_Param="--useJCEKS ${useJCEKS}"
  fi
  if [ -f "${usePkcs12keyStore}" ]
  then
    export usePkcs12keyStore_Param="--usePkcs12keyStore ${usePkcs12keyStore}"
  fi
  if [ -f "${keyStorePasswordFile}" ]
  then
    export keyStorePasswordFile_Param="--keyStorePasswordFile ${keyStorePasswordFile}"
  fi
  if [ ! -z "$certNickname" ]
  then
    export certNickname_Param="--certNickname ${certNickname}"
  fi
  if [ -f "${keyPasswordFile}" ]
  then
    export keyPasswordFile_Param="--keyPasswordFile ${keyPasswordFile} "
  fi
  if [ "${enableStartTLS}" == "true" ]
  then
    export enableStartTLS_Param="--enableStartTLS"
  fi
}

createCommonOUD_Directory() {
  echo "[$(date)] - Checking Parameters before Creating Common OUD Directory Instance"
  checkCommonInstance_Params
  #### function call for Data initialization through LDIF files #########
  checkDataLdif
  echo "[$(date)] - Creating OUD Directory Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo ${OUD_HOME}/oud-setup \
    --cli \
    --instancePath ${OUD_INST_HOME}  \
    --no-prompt \
	--noPropertiesFile \
    --rootUserDN "${rootUserDN}" \
    --rootUserPasswordFile ${rootPwdFile} \
    --baseDN ${baseDN} \
    ${dataParam} \
    ${generateSelfSignedCertificate_Param} \
    ${usePkcs11Keystore_Param} \
    ${useJavaKeystore_Param} \
    ${useJCEKS_Param} \
    ${usePkcs12keyStore_Param} \
    ${keyStorePasswordFile_Param} \
    ${certNickname_Param} \
    ${keyPasswordFile_Param} \
    ${enableStartTLS_Param} \
    ${jmxPort_Param} \
    ${eusPasswordScheme_Param} \
    ${adminConnectorPort_Param} \
    ${httpAdminConnectorPort_Param} \
    ${ldapPort_Param} \
    ${ldapsPort_Param} \
    ${httpPort_Param} \
    ${httpsPort_Param} \
	--integration ${integration} \
    --serverTuning "${serverTuning}" \
    --offlineToolsTuning "${offlineToolsTuning}" 2>&1 | tee -a ${oudSetupLogs} 
  ${OUD_HOME}/oud-setup \
    --cli \
    --instancePath ${OUD_INST_HOME}  \
    --no-prompt \
	--noPropertiesFile \
    --rootUserDN "${rootUserDN}" \
    --rootUserPasswordFile ${rootPwdFile} \
    --baseDN ${baseDN} \
    ${dataParam} \
    ${generateSelfSignedCertificate_Param} \
    ${usePkcs11Keystore_Param} \
    ${useJavaKeystore_Param} \
    ${useJCEKS_Param} \
    ${usePkcs12keyStore_Param} \
    ${keyStorePasswordFile_Param} \
    ${certNickname_Param} \
    ${keyPasswordFile_Param} \
    ${enableStartTLS_Param} \
    ${jmxPort_Param} \
    ${eusPasswordScheme_Param} \
    ${adminConnectorPort_Param} \
    ${httpAdminConnectorPort_Param} \
    ${ldapPort_Param} \
    ${ldapsPort_Param} \
    ${httpPort_Param} \
    ${httpsPort_Param} \
	--integration ${integration} \
    --serverTuning "${serverTuning}" \
    --offlineToolsTuning "${offlineToolsTuning}" 2>&1 | tee -a ${oudSetupLogs}
  echo "[$(date)] - createCommonOUD_Directory - Created OUD Instance"   2>&1 | tee -a ${oudInstanceConfigStatus}
  updateJavaProps
  java_security_config
  schemaConfig
  dstune
  dsConfig
  manageSuffix
  importLdif
}

checkCreateOUD_Directory_Params() {
  echo "[$(date)] - Checking Parameters before Creating OUD Directory Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
}

createOUD_Directory() {
  checkCreateOUD_Directory_Params
  createCommonOUD_Directory
  rebuildIndex
  execCommands
}

checkCreateOUD_Proxy_Params() {
  echo "[$(date)] - Checking Parameters before Creating OUD Proxy Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  checkCommonInstance_Params
}

createOUD_Proxy() {
  checkCreateOUD_Proxy_Params
  echo "[$(date)] - Creating OUD Proxy Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo $OUD_HOME/oud-proxy-setup \
    --cli \
    --instancePath ${OUD_INST_HOME} \
    --no-prompt \
	--noPropertiesFile \
    --adminConnectorPort ${adminConnectorPort} \
    --httpAdminConnectorPort ${httpAdminConnectorPort} \
    --rootUserDN "${rootUserDN}" \
    --rootUserPasswordFile ${rootPwdFile} \
    ${generateSelfSignedCertificate_Param} \
    ${usePkcs11Keystore_Param} \
    ${useJavaKeystore_Param} \
    ${useJCEKS_Param} \
    ${usePkcs12keyStore_Param} \
    ${keyStorePasswordFile_Param} \
    ${certNickname_Param} \
    ${keyPasswordFile_Param} \
    ${enableStartTLS_Param} \
    ${jmxPort_Param} \
    ${eusPasswordScheme_Param} \
    ${adminConnectorPort_Param} \
    ${httpAdminConnectorPort_Param} \
    ${ldapPort_Param} \
    ${ldapsPort_Param} \
    ${httpPort_Param} \
    ${httpsPort_Param} 2>&1 | tee -a ${oudProxySetupLogs}
  $OUD_HOME/oud-proxy-setup \
    --cli \
    --instancePath ${OUD_INST_HOME} \
    --no-prompt \
	--noPropertiesFile \
    --rootUserDN "${rootUserDN}" \
    --rootUserPasswordFile ${rootPwdFile} \
    ${generateSelfSignedCertificate_Param} \
    ${usePkcs11Keystore_Param} \
    ${useJavaKeystore_Param} \
    ${useJCEKS_Param} \
    ${usePkcs12keyStore_Param} \
    ${keyStorePasswordFile_Param} \
    ${certNickname_Param} \
    ${keyPasswordFile_Param} \
    ${enableStartTLS_Param} \
    ${jmxPort_Param} \
    ${eusPasswordScheme_Param} \
    ${adminConnectorPort_Param} \
    ${httpAdminConnectorPort_Param} \
    ${ldapPort_Param} \
    ${ldapsPort_Param} \
    ${httpPort_Param} \
    ${httpsPort_Param} 2>&1 | tee -a ${oudProxySetupLogs}
  echo "[$(date)] - Created OUD Proxy Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  updateJavaProps
  java_security_config
  schemaConfig
  dstune
  dsConfig
  manageSuffix
  importLdif
  rebuildIndex
  execCommands
}

checkCreate_OUD_RS_Params() {
  echo "[$(date)] - Checking Parameters before Creating OUD Replication Server Instance"
  checkCommonInstance_Params
}

createOUD_RS() {
  checkCreate_OUD_RS_Params
  echo "[$(date)] - Creating OUD Replication Server Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo ${OUD_HOME}/oud-setup \
    --cli \
    --instancePath ${OUD_INST_HOME}  \
    --no-prompt \
	--noPropertiesFile \
    --rootUserDN "${rootUserDN}" \
    --rootUserPasswordFile ${rootPwdFile} \
    ${adminConnectorPort_Param} \
    ${httpAdminConnectorPort_Param} \
    --serverTuning "${serverTuning}" \
    --offlineToolsTuning "${offlineToolsTuning}" 2>&1 | tee -a ${oudSetupLogs} 
  ${OUD_HOME}/oud-setup \
    --cli \
    --instancePath ${OUD_INST_HOME}  \
    --no-prompt \
	--noPropertiesFile \
    --rootUserDN "${rootUserDN}" \
    --rootUserPasswordFile ${rootPwdFile} \
    ${adminConnectorPort_Param} \
    ${httpAdminConnectorPort_Param} \
    --serverTuning "${serverTuning}" \
    --offlineToolsTuning "${offlineToolsTuning}" 2>&1 | tee -a ${oudSetupLogs}
  echo "[$(date)] - Created OUD Replication Server Instance" 2>&1 | tee -a ${oudInstanceConfigStatus}
  updateJavaProps
  java_security_config
  schemaConfig
  dstune
  dsConfig
  dsReplication
  post_dsreplication_dsconfig
  rebuildIndex
  execCommands
}

checkCreateOUD_DS2RS() {
  echo "[$(date)] - Checking Parameters before Creating OUD Directory Instance and add the same to Replication Server"
  checkCommonInstance_Params
}

createOUD_DS2RS() {
  checkCreateOUD_DS2RS
  echo "[$(date)] - Creating OUD Directory Instance and add the same to Replication Server" 2>&1 | tee -a ${oudInstanceConfigStatus}
  # For an additional instance in topology, no need to have sampleData seeded
  export sampleData=FALSE
  createCommonOUD_Directory
  dsReplication
  post_dsreplication_dsconfig
  rebuildIndex
  execCommands
}

# Initialize Instance Configuration Status File

if [ -f "${oudInstanceConfigStatus}" ]
then
  mv ${oudInstanceConfigStatus} ${oudInstanceConfigStatus}.$(date +%F_%H%M%S)
fi
echo "[$(date)] - Create and Start OUD Instance - Initializing..." 2>&1 | tee -a ${oudInstanceConfigStatus}  

########## Create and Start OUD Instance ##########
printEnvVars

if [ -d $OUD_INST_HOME ]; then
  echo ""
  echo "[$(date)] - Instance Home present at [${OUD_INST_HOME}]. So, Instance would NOT be created/configured." 2>&1 | tee -a ${oudInstanceConfigStatus}
  ${SCRIPT_DIR}/startOUDInstance.sh
else
  createPwdFiles
  if [ ! -z "${sleepBeforeConfig}" ]
  then
	echo "[$(date)] - Sleeping before configuration for ${sleepBeforeConfig} ..." 2>&1 | tee -a ${oudInstanceConfigStatus}
    sleep ${sleepBeforeConfig}
	echo "[$(date)] - Configuration to start now after sleeping for ${sleepBeforeConfig} ..." 2>&1 | tee -a ${oudInstanceConfigStatus}
  fi
  case $instanceType in
    "Directory") createOUD_Directory
      ;;
    "Proxy") createOUD_Proxy
      ;;
    "Replication") createOUD_RS
      ;;
    "AddDS2RS") createOUD_DS2RS
      ;;
    *) echo "[$(date)] - Invalid instanceType [$instanceType]"
	  deletePwdFiles
      exit
      ;;
  esac
  deletePwdFiles
  ${SCRIPT_DIR}/startOUDInstance.sh
fi
