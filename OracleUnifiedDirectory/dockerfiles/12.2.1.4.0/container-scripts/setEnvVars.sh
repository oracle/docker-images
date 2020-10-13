#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# Script to create OUD instance based on the passed parameters.
# 

export BASE_DIR=${BASE_DIR:-/u01}
export ORACLE_HOME=${ORACLE_HOME:-/u01/oracle}
export SCRIPT_DIR=${SCRIPT_DIR:-/u01/oracle/container-scripts}
export USER_PROJECTS_DIR=${USER_PROJECTS_DIR:-/u01/oracle/user_projects}
export OUD_INSTANCE_NAME=${OUD_INSTANCE_NAME:-asinst_1}

export OUD_INST_HOME=$USER_PROJECTS_DIR/${OUD_INSTANCE_NAME}/OUD
export OUD_HOME=$ORACLE_HOME/oud
export OUD_ADMIN_DIR=$USER_PROJECTS_DIR/${OUD_INSTANCE_NAME}/admin
export OUD_LOGS_DIR=$USER_PROJECTS_DIR/${OUD_INSTANCE_NAME}/logs
mkdir -p ${OUD_ADMIN_DIR}
mkdir -p ${OUD_LOGS_DIR}

export PATH=$PATH:${JAVA_HOME}/bin:${ORACLE_HOME}/oracle_common/common/bin:${ORACLE_HOME}/wlserver/common/bin:${OUD_INST_HOME}/bin:${SCRIPT_DIR}

export instanceType=${instanceType:-Directory}
export hostname=${hostname:-$(hostname -f)}
export ldapPort=${ldapPort:-1389}
export ldapsPort=${ldapsPort:-1636}
export rootUserDN=${rootUserDN:-}
export rootUserPassword=${rootUserPassword:-}
export baseDN=${baseDN:-dc=example,dc=com}
export adminConnectorPort=${adminConnectorPort:-1444}
export httpAdminConnectorPort=${httpAdminConnectorPort:-1888}
export httpPort=${httpPort:-1080}
export httpsPort=${httpsPort:-1081}
export sampleData=${sampleData:-0}
export integration=${integration:-no-integration}

export replicationPort=${replicationPort:-1898}
export sourceHost=${sourceHost:myoudds1}
export initializeFromHost=${initializeFromHost:-$sourceHost}
export sourceAdminConnectorPort=${sourceAdminConnectorPort:-$adminConnectorPort}
export sourceReplicationPort=${sourceReplicationPort:-$replicationPort}

export adminUID=${adminUID:-}
export adminPassword=${adminPassword:-}
export bindDN1=${bindDN1:-}
export bindPassword1=${bindPassword1:-}
export bindDN2=${bindDN2:-}
export bindPassword2=${bindPassword2:-}

export serverTuning=${serverTuning:-jvm-default}
export offlineToolsTuning=${offlineToolsTuning:-jvm-default}
export javaSecurityFile=${javaSecurityFile:-}

export generateSelfSignedCertificate=${generateSelfSignedCertificate:-true}
export usePkcs11Keystore=${usePkcs11Keystore:-}
export useJCEKS=${useJCEKS:-}
export useJavaKeystore=${useJavaKeystore:-}
export usePkcs12keyStore=${usePkcs12keyStore:-}
export keyStorePasswordFile=${keyStorePasswordFile:-}
export certNickname=${certNickname:-}
export keyPasswordFile=${keyPasswordFile:-}
export eusPasswordScheme=${eusPasswordScheme:-}
export enableStartTLS=${enableStartTLS:-}
export jmxPort=${jmxPort:-disabled}


export runStartDsInDebug=${runStartDsInDebug:-false}
export startDsDebugPort=${startDsDebugPort:-1044}
export startDsDebugSuspend=${startDsDebugSuspend:-n}

export restartOUDInstAfterConfig=${restartOUDInstAfterConfig:-false}

export restartAfterDstune=${restartAfterDstune:-false}
export restartAfterDsconfig=${restartAfterDsconfig:-false}
export restartAfterPostDsreplDsconfig=${restartAfterPostDsreplDsconfig:-false}
export restartAfterDsreplication=${restartAfterDsreplication:-false}
export restartAfterJavaSecurityFile=${restartAfterJavaSecurityFile:-false}
export restartAfterSchemaConfig=${restartAfterSchemaConfig:-false}
export restartAfterRebuildIndex=${restartAfterRebuildIndex:-false}
export restartAfterManageSuffix=${restartAfterManageSuffix:-false}
export restartAfterImportLdif=${restartAfterImportLdif:-false}

export ignoreErrorDstune=${ignoreErrorDstune:-true}
export ignoreErrorDsconfig=${ignoreErrorDsconfig:-true}
export ignoreErrorPostDsreplDsconfig=${ignoreErrorPostDsreplDsconfig:-true}
export ignoreErrorDsreplication=${ignoreErrorDsreplication:-true}
export ignoreErrorSchemaConfig=${ignoreErrorSchemaConfig:-true}
export ignoreErrorRebuildIndex=${ignoreErrorRebuildIndex:-true}
export ignoreErrorManageSuffix=${ignoreErrorManageSuffix:-true}
export ignoreErrorImportLdif=${ignoreErrorImportLdif:-true}
export ignoreErrorExecCmd=${ignoreErrorExecCmd:-true}

export rootPwdFile=${OUD_ADMIN_DIR}/rootPwdFile.txt
export adminPwdFile=${OUD_ADMIN_DIR}/adminPwdFile.txt
export bindPwdFile1=${OUD_ADMIN_DIR}/bindPwdFile1.txt
export bindPwdFile2=${OUD_ADMIN_DIR}/bindPwdFile2.txt

export oudSetupLogs=${OUD_LOGS_DIR}/oud-setup.log
export oudProxySetupLogs=${OUD_LOGS_DIR}/oud-proxy-setup.log
export dsconfigCmdLogs=${OUD_LOGS_DIR}/dsconfigCmd.log
export dstuneCmdLogs=${OUD_LOGS_DIR}/dstuneCmd.log
export dsreplicationCmdLogs=${OUD_LOGS_DIR}/dsreplicationCmd.log
export rebuildIndexCmdLogs=${OUD_LOGS_DIR}/rebuildIndexCmd.log
export manageSuffixCmdLogs=${OUD_LOGS_DIR}/manageSuffixCmd.log
export importLdifCmdLogs=${OUD_LOGS_DIR}/importLdifCmd.log
export execCmdCmdLogs=${OUD_LOGS_DIR}/execCmdCmd.log
export startDsCmdLogs=${OUD_LOGS_DIR}/startDsCmd.log
export stopDsCmdLogs=${OUD_LOGS_DIR}/stopDsCmd.log

export oudInstanceConfigStatus=${OUD_LOGS_DIR}/oudInstConfigStatus.log

export oudInstanceDetailsFile=${OUD_ADMIN_DIR}/instance_version.txt

export sleepBeforeConfig=${sleepBeforeConfig:-1}
