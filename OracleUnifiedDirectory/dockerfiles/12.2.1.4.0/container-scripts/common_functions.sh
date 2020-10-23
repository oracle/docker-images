#!/bin/bash
# 
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Script for common functions which can be used while OUD instance setup/configuration.
# It's assumed that setEnvVars.sh is already sourced before sourcing this script file.

## Function to restart OUD Instance
restartOUD() {
  echo "[$(date)] - restartOUD - Stopping..." 2>&1 | tee -a ${oudInstanceConfigStatus}
  ${OUD_INST_HOME}/bin/stop-ds 2>&1 | tee -a ${stopDsCmdLogs}
  echo "[$(date)] - Invoking start-ds ..." 2>&1 | tee -a ${oudInstanceConfigStatus}
  ${OUD_INST_HOME}/bin/start-ds 2>&1 | tee -a ${startDsCmdLogs}
}

############ Wait for Server to be available ##############

function waitForServerPort() {

  connectString="${1}/${2}"

  echo "[$(date)] - Waiting for Server on ${connectString} to become available..."
  while :
  do
    (echo > /dev/tcp/${connectString}) >/dev/null 2>&1
    available=$?
    if [[ $available -eq 0 ]]; then
      echo "[$(date)] - Server (${connectString}) is now available. Proceeding..."
      break
    fi
    sleep 1
  done
}

function waitForHostColPort() {
  input="${1}"
  OLDIFS=$IFS
  echo ${input} | while IFS=':' read -r h p
  do
    waitForServerPort ${h} ${p}
  done
  IFS=$OLDIFS
}

function waitForSourceServerPorts() {
  input="${1}"
  OLDIFS=$IFS
  echo ${input} | while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9
  do
	IFS=$OLDIFS
    if [ ! -z "${f1}" ]; then waitForHostColPort "${f1}"; fi
    if [ ! -z "${f2}" ]; then waitForHostColPort "${f2}"; fi
    if [ ! -z "${f3}" ]; then waitForHostColPort "${f3}"; fi
    if [ ! -z "${f4}" ]; then waitForHostColPort "${f4}"; fi
    if [ ! -z "${f5}" ]; then waitForHostColPort "${f5}"; fi
    if [ ! -z "${f6}" ]; then waitForHostColPort "${f6}"; fi
    if [ ! -z "${f7}" ]; then waitForHostColPort "${f7}"; fi
    if [ ! -z "${f8}" ]; then waitForHostColPort "${f8}"; fi
    if [ ! -z "${f9}" ]; then waitForHostColPort "${f9}"; fi
  done
  IFS=$OLDIFS
}

printLdifFileParams() {
  i=0
  echo -n "ldifFile Parameters: "	
  for ldifFileParam in "${ldifFile_1}" "${ldifFile_2}" "${ldifFile_3}" "${ldifFile_4}" "${ldifFile_5}" "${ldifFile_6}" "${ldifFile_7}" "${ldifFile_8}" "${ldifFile_9}" "${ldifFile_10}" "${ldifFile_11}" "${ldifFile_12}" "${ldifFile_13}" "${ldifFile_14}" "${ldifFile_15}" "${ldifFile_16}" "${ldifFile_17}" "${ldifFile_18}" "${ldifFile_19}" "${ldifFile_20}" "${ldifFile_21}" "${ldifFile_22}" "${ldifFile_23}" "${ldifFile_24}" "${ldifFile_25}" "${ldifFile_26}" "${ldifFile_27}" "${ldifFile_28}" "${ldifFile_29}" "${ldifFile_30}" "${ldifFile_31}" "${ldifFile_32}" "${ldifFile_33}" "${ldifFile_34}" "${ldifFile_35}" "${ldifFile_36}" "${ldifFile_37}" "${ldifFile_38}" "${ldifFile_39}" "${ldifFile_40}" "${ldifFile_41}" "${ldifFile_42}" "${ldifFile_43}" "${ldifFile_44}" "${ldifFile_45}" "${ldifFile_46}" "${ldifFile_47}" "${ldifFile_48}" "${ldifFile_49}" "${ldifFile_50}" 
  do
	i=$(expr $i + 1)
	if [ ! -z "${ldifFileParam}" ]
	then
	  echo -n "ldifFile_${i} [${ldifFileParam}] "
    fi
  done
  echo ""
}

#####################dstune ######################

printDstuneParams() {
  i=0
  echo -n "dstune Parameters: "	
  for dstuneParam in "${dstune_1}" "${dstune_2}" "${dstune_3}" "${dstune_4}" "${dstune_5}" "${dstune_6}" "${dstune_7}" "${dstune_8}" "${dstune_9}" "${dstune_10}" "${dstune_11}" "${dstune_12}" "${dstune_13}" "${dstune_14}" "${dstune_15}" "${dstune_16}" "${dstune_17}" "${dstune_18}" "${dstune_19}" "${dstune_20}" "${dstune_21}" "${dstune_22}" "${dstune_23}" "${dstune_24}" "${dstune_25}" "${dstune_26}" "${dstune_27}" "${dstune_28}" "${dstune_29}" "${dstune_30}" "${dstune_31}" "${dstune_32}" "${dstune_33}" "${dstune_34}" "${dstune_35}" "${dstune_36}" "${dstune_37}" "${dstune_38}" "${dstune_39}" "${dstune_40}" "${dstune_41}" "${dstune_42}" "${dstune_43}" "${dstune_44}" "${dstune_45}" "${dstune_46}" "${dstune_47}" "${dstune_48}" "${dstune_49}" "${dstune_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${dstuneParam}" ]
	then
	  echo -n "dstune_${i} [${dstuneParam}] "
    fi
  done
  echo ""
}

dstune() {
    if [ -z "${dstune_1}" ]
    then
      return
    fi
    echo "[$(date)] - dstune - Starting" 2>&1 | tee -a ${oudInstanceConfigStatus}
    echo "[$(date)] - Executing dstune commands" >> ${dstuneCmdLogs}
    echo "[$(date)] - Before running dstune command(s), let's check the status" >> ${dstuneCmdLogs}
    ${SCRIPT_DIR}/checkOUDInstance.sh
    checkOudError=$?
    if [ ${checkOudError} -gt 0 ]; then
      echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
      exit 1
    fi
    
    for dstuneParam in "${dstune_1}" "${dstune_2}" "${dstune_3}" "${dstune_4}" "${dstune_5}" "${dstune_6}" "${dstune_7}" "${dstune_8}" "${dstune_9}" "${dstune_10}" "${dstune_11}" "${dstune_12}" "${dstune_13}" "${dstune_14}" "${dstune_15}" "${dstune_16}" "${dstune_17}" "${dstune_18}" "${dstune_19}" "${dstune_20}" "${dstune_21}" "${dstune_22}" "${dstune_23}" "${dstune_24}" "${dstune_25}" "${dstune_26}" "${dstune_27}" "${dstune_28}" "${dstune_29}" "${dstune_30}" "${dstune_31}" "${dstune_32}" "${dstune_33}" "${dstune_34}" "${dstune_35}" "${dstune_36}" "${dstune_37}" "${dstune_38}" "${dstune_39}" "${dstune_40}" "${dstune_41}" "${dstune_42}" "${dstune_43}" "${dstune_44}" "${dstune_45}" "${dstune_46}" "${dstune_47}" "${dstune_48}" "${dstune_49}" "${dstune_50}"
    do
      if [ ! -z "${dstuneParam}" ]
      then
        echo "[$(date)] - Executing dstune with parameters ${dstuneParam}" >> ${dstuneCmdLogs}
        echo ${OUD_INST_HOME}/bin/dstune \
             ${dstuneParam} \
             --no-prompt  >> ${dstuneCmdLogs}
        ${OUD_INST_HOME}/bin/dstune \
             ${dstuneParam} \
             --no-prompt > ${dstuneCmdLogs}.tmp 2>&1
        execStatus=$?
		cat ${dstuneCmdLogs}.tmp | tee -a ${dstuneCmdLogs}
        echo "[$(date)] - execStatus [${execStatus}]"
        if [ ${execStatus} -gt 0 -a "${ignoreErrorDstune}" = "false" ]
        then
          echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorDstune=false, exiting ..."
          exit 1
        fi
      fi
    done
    echo ${OUD_INST_HOME}/bin/dstune \
         list \
         --no-prompt  >> ${dstuneCmdLogs}
    ${OUD_INST_HOME}/bin/dstune \
      	list \
        --no-prompt  2>&1 | tee -a ${dstuneCmdLogs}
	
	echo "[$(date)] - Executed all configured dstune commands." 2>&1 | tee -a ${oudInstanceConfigStatus}

    echo "[$(date)] - Setting the flag for restarting OUD Instance to have JVM parameters in affect" \
      2>&1 | tee -a ${dstuneCmdLogs}
    export restartOUDInstAfterConfig=true
	if [ "${restartAfterDstune}" = "true" ]
	then
	  restartOUDInstAfterConfig=false
	  restartOUD
	fi
}

##################### dstune #########################

############ dsconfig ###########

printDsConfigParams() {
  i=0
  echo -n "dsconfig Parameters: "	
  for dsconfigParam in "${dsconfig_1}" "${dsconfig_2}" "${dsconfig_3}" "${dsconfig_4}" "${dsconfig_5}" "${dsconfig_6}" "${dsconfig_7}" "${dsconfig_8}" "${dsconfig_9}" "${dsconfig_10}" "${dsconfig_11}" "${dsconfig_12}" "${dsconfig_13}" "${dsconfig_14}" "${dsconfig_15}" "${dsconfig_16}" "${dsconfig_17}" "${dsconfig_18}" "${dsconfig_19}" "${dsconfig_20}" "${dsconfig_21}" "${dsconfig_22}" "${dsconfig_23}" "${dsconfig_24}" "${dsconfig_25}" "${dsconfig_26}" "${dsconfig_27}" "${dsconfig_28}" "${dsconfig_29}" "${dsconfig_30}" "${dsconfig_31}" "${dsconfig_32}" "${dsconfig_33}" "${dsconfig_34}" "${dsconfig_35}" "${dsconfig_36}" "${dsconfig_37}" "${dsconfig_38}" "${dsconfig_39}" "${dsconfig_40}" "${dsconfig_41}" "${dsconfig_42}" "${dsconfig_43}" "${dsconfig_44}" "${dsconfig_45}" "${dsconfig_46}" "${dsconfig_47}" "${dsconfig_48}" "${dsconfig_49}" "${dsconfig_50}" "${dsconfig_51}" "${dsconfig_52}" "${dsconfig_53}" "${dsconfig_54}" "${dsconfig_55}" "${dsconfig_56}" "${dsconfig_57}" "${dsconfig_58}" "${dsconfig_59}" "${dsconfig_60}" "${dsconfig_61}" "${dsconfig_62}" "${dsconfig_63}" "${dsconfig_64}" "${dsconfig_65}" "${dsconfig_66}" "${dsconfig_67}" "${dsconfig_68}" "${dsconfig_69}" "${dsconfig_70}" "${dsconfig_71}" "${dsconfig_72}" "${dsconfig_73}" "${dsconfig_74}" "${dsconfig_75}" "${dsconfig_76}" "${dsconfig_77}" "${dsconfig_78}" "${dsconfig_79}" "${dsconfig_80}" "${dsconfig_81}" "${dsconfig_82}" "${dsconfig_83}" "${dsconfig_84}" "${dsconfig_85}" "${dsconfig_86}" "${dsconfig_87}" "${dsconfig_88}" "${dsconfig_89}" "${dsconfig_90}" "${dsconfig_91}" "${dsconfig_92}" "${dsconfig_93}" "${dsconfig_94}" "${dsconfig_95}" "${dsconfig_96}" "${dsconfig_97}" "${dsconfig_98}" "${dsconfig_99}" "${dsconfig_100}" "${dsconfig_101}" "${dsconfig_102}" "${dsconfig_103}" "${dsconfig_104}" "${dsconfig_105}" "${dsconfig_106}" "${dsconfig_107}" "${dsconfig_108}" "${dsconfig_109}" "${dsconfig_110}" "${dsconfig_111}" "${dsconfig_112}" "${dsconfig_113}" "${dsconfig_114}" "${dsconfig_115}" "${dsconfig_116}" "${dsconfig_117}" "${dsconfig_118}" "${dsconfig_119}" "${dsconfig_120}" "${dsconfig_121}" "${dsconfig_122}" "${dsconfig_123}" "${dsconfig_124}" "${dsconfig_125}" "${dsconfig_126}" "${dsconfig_127}" "${dsconfig_128}" "${dsconfig_129}" "${dsconfig_130}" "${dsconfig_131}" "${dsconfig_132}" "${dsconfig_133}" "${dsconfig_134}" "${dsconfig_135}" "${dsconfig_136}" "${dsconfig_137}" "${dsconfig_138}" "${dsconfig_139}" "${dsconfig_140}" "${dsconfig_141}" "${dsconfig_142}" "${dsconfig_143}" "${dsconfig_144}" "${dsconfig_145}" "${dsconfig_146}" "${dsconfig_147}" "${dsconfig_148}" "${dsconfig_149}" "${dsconfig_150}" "${dsconfig_151}" "${dsconfig_152}" "${dsconfig_153}" "${dsconfig_154}" "${dsconfig_155}" "${dsconfig_156}" "${dsconfig_157}" "${dsconfig_158}" "${dsconfig_159}" "${dsconfig_160}" "${dsconfig_161}" "${dsconfig_162}" "${dsconfig_163}" "${dsconfig_164}" "${dsconfig_165}" "${dsconfig_166}" "${dsconfig_167}" "${dsconfig_168}" "${dsconfig_169}" "${dsconfig_170}" "${dsconfig_171}" "${dsconfig_172}" "${dsconfig_173}" "${dsconfig_174}" "${dsconfig_175}" "${dsconfig_176}" "${dsconfig_177}" "${dsconfig_178}" "${dsconfig_179}" "${dsconfig_180}" "${dsconfig_181}" "${dsconfig_182}" "${dsconfig_183}" "${dsconfig_184}" "${dsconfig_185}" "${dsconfig_186}" "${dsconfig_187}" "${dsconfig_188}" "${dsconfig_189}" "${dsconfig_190}" "${dsconfig_191}" "${dsconfig_192}" "${dsconfig_193}" "${dsconfig_194}" "${dsconfig_195}" "${dsconfig_196}" "${dsconfig_197}" "${dsconfig_198}" "${dsconfig_199}" "${dsconfig_200}" "${dsconfig_201}" "${dsconfig_202}" "${dsconfig_203}" "${dsconfig_204}" "${dsconfig_205}" "${dsconfig_206}" "${dsconfig_207}" "${dsconfig_208}" "${dsconfig_209}" "${dsconfig_210}" "${dsconfig_211}" "${dsconfig_212}" "${dsconfig_213}" "${dsconfig_214}" "${dsconfig_215}" "${dsconfig_216}" "${dsconfig_217}" "${dsconfig_218}" "${dsconfig_219}" "${dsconfig_220}" "${dsconfig_221}" "${dsconfig_222}" "${dsconfig_223}" "${dsconfig_224}" "${dsconfig_225}" "${dsconfig_226}" "${dsconfig_227}" "${dsconfig_228}" "${dsconfig_229}" "${dsconfig_230}" "${dsconfig_231}" "${dsconfig_232}" "${dsconfig_233}" "${dsconfig_234}" "${dsconfig_235}" "${dsconfig_236}" "${dsconfig_237}" "${dsconfig_238}" "${dsconfig_239}" "${dsconfig_240}" "${dsconfig_241}" "${dsconfig_242}" "${dsconfig_243}" "${dsconfig_244}" "${dsconfig_245}" "${dsconfig_246}" "${dsconfig_247}" "${dsconfig_248}" "${dsconfig_249}" "${dsconfig_250}" "${dsconfig_251}" "${dsconfig_252}" "${dsconfig_253}" "${dsconfig_254}" "${dsconfig_255}" "${dsconfig_256}" "${dsconfig_257}" "${dsconfig_258}" "${dsconfig_259}" "${dsconfig_260}" "${dsconfig_261}" "${dsconfig_262}" "${dsconfig_263}" "${dsconfig_264}" "${dsconfig_265}" "${dsconfig_266}" "${dsconfig_267}" "${dsconfig_268}" "${dsconfig_269}" "${dsconfig_270}" "${dsconfig_271}" "${dsconfig_272}" "${dsconfig_273}" "${dsconfig_274}" "${dsconfig_275}" "${dsconfig_276}" "${dsconfig_277}" "${dsconfig_278}" "${dsconfig_279}" "${dsconfig_280}" "${dsconfig_281}" "${dsconfig_282}" "${dsconfig_283}" "${dsconfig_284}" "${dsconfig_285}" "${dsconfig_286}" "${dsconfig_287}" "${dsconfig_288}" "${dsconfig_289}" "${dsconfig_290}" "${dsconfig_291}" "${dsconfig_292}" "${dsconfig_293}" "${dsconfig_294}" "${dsconfig_295}" "${dsconfig_296}" "${dsconfig_297}" "${dsconfig_298}" "${dsconfig_299}" "${dsconfig_300}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${dsconfigParam}" ]
	then
	  echo -n "dsconfig_${i} [${dsconfigParam}] "
    fi
  done
  echo ""
}

dsConfig_N() {
  if [ -z "${dsconfig_1}" ]
  then
    return
  fi		
  echo "[$(date)] - Executing dsconfig commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo "[$(date)] - Before running dsconfig command(s), let's check the status"
  ${SCRIPT_DIR}/checkOUDInstance.sh
  checkOudError=$?
  if [ ${checkOudError} -gt 0 ]; then
    echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
	deletePwdFiles  
    exit 1
  fi

  # Before invoking dsconfig command, let's wait for port to be accessible
  waitForServerPort ${hostname} ${adminConnectorPort}
  waitForSourceServerPorts "${sourceServerPorts}"
  
  for dsconfigParam in "${dsconfig_1}" "${dsconfig_2}" "${dsconfig_3}" "${dsconfig_4}" "${dsconfig_5}" "${dsconfig_6}" "${dsconfig_7}" "${dsconfig_8}" "${dsconfig_9}" "${dsconfig_10}" "${dsconfig_11}" "${dsconfig_12}" "${dsconfig_13}" "${dsconfig_14}" "${dsconfig_15}" "${dsconfig_16}" "${dsconfig_17}" "${dsconfig_18}" "${dsconfig_19}" "${dsconfig_20}" "${dsconfig_21}" "${dsconfig_22}" "${dsconfig_23}" "${dsconfig_24}" "${dsconfig_25}" "${dsconfig_26}" "${dsconfig_27}" "${dsconfig_28}" "${dsconfig_29}" "${dsconfig_30}" "${dsconfig_31}" "${dsconfig_32}" "${dsconfig_33}" "${dsconfig_34}" "${dsconfig_35}" "${dsconfig_36}" "${dsconfig_37}" "${dsconfig_38}" "${dsconfig_39}" "${dsconfig_40}" "${dsconfig_41}" "${dsconfig_42}" "${dsconfig_43}" "${dsconfig_44}" "${dsconfig_45}" "${dsconfig_46}" "${dsconfig_47}" "${dsconfig_48}" "${dsconfig_49}" "${dsconfig_50}" "${dsconfig_51}" "${dsconfig_52}" "${dsconfig_53}" "${dsconfig_54}" "${dsconfig_55}" "${dsconfig_56}" "${dsconfig_57}" "${dsconfig_58}" "${dsconfig_59}" "${dsconfig_60}" "${dsconfig_61}" "${dsconfig_62}" "${dsconfig_63}" "${dsconfig_64}" "${dsconfig_65}" "${dsconfig_66}" "${dsconfig_67}" "${dsconfig_68}" "${dsconfig_69}" "${dsconfig_70}" "${dsconfig_71}" "${dsconfig_72}" "${dsconfig_73}" "${dsconfig_74}" "${dsconfig_75}" "${dsconfig_76}" "${dsconfig_77}" "${dsconfig_78}" "${dsconfig_79}" "${dsconfig_80}" "${dsconfig_81}" "${dsconfig_82}" "${dsconfig_83}" "${dsconfig_84}" "${dsconfig_85}" "${dsconfig_86}" "${dsconfig_87}" "${dsconfig_88}" "${dsconfig_89}" "${dsconfig_90}" "${dsconfig_91}" "${dsconfig_92}" "${dsconfig_93}" "${dsconfig_94}" "${dsconfig_95}" "${dsconfig_96}" "${dsconfig_97}" "${dsconfig_98}" "${dsconfig_99}" "${dsconfig_100}" "${dsconfig_101}" "${dsconfig_102}" "${dsconfig_103}" "${dsconfig_104}" "${dsconfig_105}" "${dsconfig_106}" "${dsconfig_107}" "${dsconfig_108}" "${dsconfig_109}" "${dsconfig_110}" "${dsconfig_111}" "${dsconfig_112}" "${dsconfig_113}" "${dsconfig_114}" "${dsconfig_115}" "${dsconfig_116}" "${dsconfig_117}" "${dsconfig_118}" "${dsconfig_119}" "${dsconfig_120}" "${dsconfig_121}" "${dsconfig_122}" "${dsconfig_123}" "${dsconfig_124}" "${dsconfig_125}" "${dsconfig_126}" "${dsconfig_127}" "${dsconfig_128}" "${dsconfig_129}" "${dsconfig_130}" "${dsconfig_131}" "${dsconfig_132}" "${dsconfig_133}" "${dsconfig_134}" "${dsconfig_135}" "${dsconfig_136}" "${dsconfig_137}" "${dsconfig_138}" "${dsconfig_139}" "${dsconfig_140}" "${dsconfig_141}" "${dsconfig_142}" "${dsconfig_143}" "${dsconfig_144}" "${dsconfig_145}" "${dsconfig_146}" "${dsconfig_147}" "${dsconfig_148}" "${dsconfig_149}" "${dsconfig_150}" "${dsconfig_151}" "${dsconfig_152}" "${dsconfig_153}" "${dsconfig_154}" "${dsconfig_155}" "${dsconfig_156}" "${dsconfig_157}" "${dsconfig_158}" "${dsconfig_159}" "${dsconfig_160}" "${dsconfig_161}" "${dsconfig_162}" "${dsconfig_163}" "${dsconfig_164}" "${dsconfig_165}" "${dsconfig_166}" "${dsconfig_167}" "${dsconfig_168}" "${dsconfig_169}" "${dsconfig_170}" "${dsconfig_171}" "${dsconfig_172}" "${dsconfig_173}" "${dsconfig_174}" "${dsconfig_175}" "${dsconfig_176}" "${dsconfig_177}" "${dsconfig_178}" "${dsconfig_179}" "${dsconfig_180}" "${dsconfig_181}" "${dsconfig_182}" "${dsconfig_183}" "${dsconfig_184}" "${dsconfig_185}" "${dsconfig_186}" "${dsconfig_187}" "${dsconfig_188}" "${dsconfig_189}" "${dsconfig_190}" "${dsconfig_191}" "${dsconfig_192}" "${dsconfig_193}" "${dsconfig_194}" "${dsconfig_195}" "${dsconfig_196}" "${dsconfig_197}" "${dsconfig_198}" "${dsconfig_199}" "${dsconfig_200}" "${dsconfig_201}" "${dsconfig_202}" "${dsconfig_203}" "${dsconfig_204}" "${dsconfig_205}" "${dsconfig_206}" "${dsconfig_207}" "${dsconfig_208}" "${dsconfig_209}" "${dsconfig_210}" "${dsconfig_211}" "${dsconfig_212}" "${dsconfig_213}" "${dsconfig_214}" "${dsconfig_215}" "${dsconfig_216}" "${dsconfig_217}" "${dsconfig_218}" "${dsconfig_219}" "${dsconfig_220}" "${dsconfig_221}" "${dsconfig_222}" "${dsconfig_223}" "${dsconfig_224}" "${dsconfig_225}" "${dsconfig_226}" "${dsconfig_227}" "${dsconfig_228}" "${dsconfig_229}" "${dsconfig_230}" "${dsconfig_231}" "${dsconfig_232}" "${dsconfig_233}" "${dsconfig_234}" "${dsconfig_235}" "${dsconfig_236}" "${dsconfig_237}" "${dsconfig_238}" "${dsconfig_239}" "${dsconfig_240}" "${dsconfig_241}" "${dsconfig_242}" "${dsconfig_243}" "${dsconfig_244}" "${dsconfig_245}" "${dsconfig_246}" "${dsconfig_247}" "${dsconfig_248}" "${dsconfig_249}" "${dsconfig_250}" "${dsconfig_251}" "${dsconfig_252}" "${dsconfig_253}" "${dsconfig_254}" "${dsconfig_255}" "${dsconfig_256}" "${dsconfig_257}" "${dsconfig_258}" "${dsconfig_259}" "${dsconfig_260}" "${dsconfig_261}" "${dsconfig_262}" "${dsconfig_263}" "${dsconfig_264}" "${dsconfig_265}" "${dsconfig_266}" "${dsconfig_267}" "${dsconfig_268}" "${dsconfig_269}" "${dsconfig_270}" "${dsconfig_271}" "${dsconfig_272}" "${dsconfig_273}" "${dsconfig_274}" "${dsconfig_275}" "${dsconfig_276}" "${dsconfig_277}" "${dsconfig_278}" "${dsconfig_279}" "${dsconfig_280}" "${dsconfig_281}" "${dsconfig_282}" "${dsconfig_283}" "${dsconfig_284}" "${dsconfig_285}" "${dsconfig_286}" "${dsconfig_287}" "${dsconfig_288}" "${dsconfig_289}" "${dsconfig_290}" "${dsconfig_291}" "${dsconfig_292}" "${dsconfig_293}" "${dsconfig_294}" "${dsconfig_295}" "${dsconfig_296}" "${dsconfig_297}" "${dsconfig_298}" "${dsconfig_299}" "${dsconfig_300}"
  do
	if [ ! -z "${dsconfigParam}" ]
	then	 
      updatedParam=$(echo ${dsconfigParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
  	  echo "[$(date)] - Executing dsconfig with parameters ${dsconfigParam} -> ${updatedParam}"
	  dsconfigParam=${updatedParam}
      echo eval ${OUD_INST_HOME}/bin/dsconfig \
  	    --no-prompt \
        --hostname ${hostname} \
        --port ${adminConnectorPort} \
  	    --bindDN '"${rootUserDN}"' \
  	    --bindPasswordFile ${rootPwdFile} \
  	    --trustAll \
		${dsconfigParam} >> ${dsconfigCmdLogs}

      eval ${OUD_INST_HOME}/bin/dsconfig \
  	    --no-prompt \
        --hostname ${hostname} \
        --port ${adminConnectorPort} \
  	    --bindDN '"${rootUserDN}"' \
  	    --bindPasswordFile ${rootPwdFile} \
  	    --trustAll \
  	    ${dsconfigParam} > ${dsconfigCmdLogs}.tmp 2>&1
      execStatus=$?
	  cat ${dsconfigCmdLogs}.tmp | tee -a ${dsconfigCmdLogs}
      echo "[$(date)] - execStatus [${execStatus}]"
      if [ ${execStatus} -gt 0 -a "${ignoreErrorDsconfig}" = "false" ]
      then
        echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorDsconfig=false, exiting ..."
        exit 1
      fi
	fi
  done
  echo "[$(date)] - Executed all configured dsconfig commands." 2>&1 | tee -a ${oudInstanceConfigStatus}
}

printDsconfigBatchFileParams() {
  i=0
  echo -n "dsconfigBatchFile Parameters: "	
  for dsconfigBatchFileParam in "${dsconfigBatchFile_1}" "${dsconfigBatchFile_2}" "${dsconfigBatchFile_3}" "${dsconfigBatchFile_4}" "${dsconfigBatchFile_5}" "${dsconfigBatchFile_6}" "${dsconfigBatchFile_7}" "${dsconfigBatchFile_8}" "${dsconfigBatchFile_9}" "${dsconfigBatchFile_10}" "${dsconfigBatchFile_11}" "${dsconfigBatchFile_12}" "${dsconfigBatchFile_13}" "${dsconfigBatchFile_14}" "${dsconfigBatchFile_15}" "${dsconfigBatchFile_16}" "${dsconfigBatchFile_17}" "${dsconfigBatchFile_18}" "${dsconfigBatchFile_19}" "${dsconfigBatchFile_20}" "${dsconfigBatchFile_21}" "${dsconfigBatchFile_22}" "${dsconfigBatchFile_23}" "${dsconfigBatchFile_24}" "${dsconfigBatchFile_25}" "${dsconfigBatchFile_26}" "${dsconfigBatchFile_27}" "${dsconfigBatchFile_28}" "${dsconfigBatchFile_29}" "${dsconfigBatchFile_30}" "${dsconfigBatchFile_31}" "${dsconfigBatchFile_32}" "${dsconfigBatchFile_33}" "${dsconfigBatchFile_34}" "${dsconfigBatchFile_35}" "${dsconfigBatchFile_36}" "${dsconfigBatchFile_37}" "${dsconfigBatchFile_38}" "${dsconfigBatchFile_39}" "${dsconfigBatchFile_40}" "${dsconfigBatchFile_41}" "${dsconfigBatchFile_42}" "${dsconfigBatchFile_43}" "${dsconfigBatchFile_44}" "${dsconfigBatchFile_45}" "${dsconfigBatchFile_46}" "${dsconfigBatchFile_47}" "${dsconfigBatchFile_48}" "${dsconfigBatchFile_49}" "${dsconfigBatchFile_50}" 
  do
	i=$(expr $i + 1)
	if [ ! -z "${dsconfigBatchFileParam}" ]
	then
	  echo -n "dsconfigBatchFile_${i} [${dsconfigBatchFileParam}] "
    fi
  done
  echo ""
}

dsConfigBatch() {
  if [ -z "${dsconfigBatchFile_1}" -o ! -f "${dsconfigBatchFile_1}" ]
  then
    return
  fi 
  echo "[$(date)] - Executing dsconfigBatch" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo "[$(date)] - Before running dsconfigBatch command(s), let's check the status"
  ${SCRIPT_DIR}/checkOUDInstance.sh
  checkOudError=$?
  if [ ${checkOudError} -gt 0 ]; then
    echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
	deletePwdFiles  
    exit 1
  fi

  # Before invoking dsconfig command, let's wait for port to be accessible
  waitForServerPort ${hostname} ${adminConnectorPort}
  waitForSourceServerPorts "${sourceServerPorts}"
  
  for dsconfigBatchFile in "${dsconfigBatchFile_1}" "${dsconfigBatchFile_2}" "${dsconfigBatchFile_3}" "${dsconfigBatchFile_4}" "${dsconfigBatchFile_5}" "${dsconfigBatchFile_6}" "${dsconfigBatchFile_7}" "${dsconfigBatchFile_8}" "${dsconfigBatchFile_9}" "${dsconfigBatchFile_10}" "${dsconfigBatchFile_11}" "${dsconfigBatchFile_12}" "${dsconfigBatchFile_13}" "${dsconfigBatchFile_14}" "${dsconfigBatchFile_15}" "${dsconfigBatchFile_16}" "${dsconfigBatchFile_17}" "${dsconfigBatchFile_18}" "${dsconfigBatchFile_19}" "${dsconfigBatchFile_20}" "${dsconfigBatchFile_21}" "${dsconfigBatchFile_22}" "${dsconfigBatchFile_23}" "${dsconfigBatchFile_24}" "${dsconfigBatchFile_25}" "${dsconfigBatchFile_26}" "${dsconfigBatchFile_27}" "${dsconfigBatchFile_28}" "${dsconfigBatchFile_29}" "${dsconfigBatchFile_30}" "${dsconfigBatchFile_31}" "${dsconfigBatchFile_32}" "${dsconfigBatchFile_33}" "${dsconfigBatchFile_34}" "${dsconfigBatchFile_35}" "${dsconfigBatchFile_36}" "${dsconfigBatchFile_37}" "${dsconfigBatchFile_38}" "${dsconfigBatchFile_39}" "${dsconfigBatchFile_40}" "${dsconfigBatchFile_41}" "${dsconfigBatchFile_42}" "${dsconfigBatchFile_43}" "${dsconfigBatchFile_44}" "${dsconfigBatchFile_45}" "${dsconfigBatchFile_46}" "${dsconfigBatchFile_47}" "${dsconfigBatchFile_48}" "${dsconfigBatchFile_49}" "${dsconfigBatchFile_50}" 
  do
	if [ ! -z "${dsconfigBatchFile}" -a -f "${dsconfigBatchFile}" ]
	then	 
  	  echo "[$(date)] - Executing dsconfig with Batch File ${dsconfigBatchFile}" 2>&1 | tee -a ${oudInstanceConfigStatus}
      echo ${OUD_INST_HOME}/bin/dsconfig \
  	    --no-prompt \
        --hostname ${hostname} \
        --port ${adminConnectorPort} \
  	    --bindDN "${rootUserDN}" \
  	    --bindPasswordFile ${rootPwdFile} \
  	    --trustAll \
		--batchFilePath ${dsconfigBatchFile} >> ${dsconfigCmdLogs}

      ${OUD_INST_HOME}/bin/dsconfig \
  	    --no-prompt \
        --hostname ${hostname} \
        --port ${adminConnectorPort} \
  	    --bindDN "${rootUserDN}" \
  	    --bindPasswordFile ${rootPwdFile} \
  	    --trustAll \
  	    --batchFilePath ${dsconfigBatchFile} > ${dsconfigCmdLogs}.tmp 2>&1
      execStatus=$?
	  cat ${dsconfigCmdLogs}.tmp | tee -a ${dsconfigCmdLogs}
      echo "[$(date)] - execStatus [${execStatus}]"
      if [ ${execStatus} -gt 0 -a "${ignoreErrorDsconfig}" = "false" ]
      then
        echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorDsconfig=false, exiting ..."
        exit 1
      fi
	fi
  done
  echo "[$(date)] - Executed all configured dsconfig commands from all dsconfigBatch files" 2>&1 | tee -a ${oudInstanceConfigStatus}
}

dsConfig() {
  dsConfigBatch
  dsConfig_N
  if [ "${restartAfterDsconfig}" = "true" ]
  then
    restartOUD
  fi
}

printPost_dsreplication_dsconfigParams() {
  i=0
  echo -n "post_dsreplication_dsconfig Parameters: "	
  for post_dsreplication_dsconfigParam in "${post_dsreplication_dsconfig_1}" "${post_dsreplication_dsconfig_2}" "${post_dsreplication_dsconfig_3}" "${post_dsreplication_dsconfig_4}" "${post_dsreplication_dsconfig_5}" "${post_dsreplication_dsconfig_6}" "${post_dsreplication_dsconfig_7}" "${post_dsreplication_dsconfig_8}" "${post_dsreplication_dsconfig_9}" "${post_dsreplication_dsconfig_10}" "${post_dsreplication_dsconfig_11}" "${post_dsreplication_dsconfig_12}" "${post_dsreplication_dsconfig_13}" "${post_dsreplication_dsconfig_14}" "${post_dsreplication_dsconfig_15}" "${post_dsreplication_dsconfig_16}" "${post_dsreplication_dsconfig_17}" "${post_dsreplication_dsconfig_18}" "${post_dsreplication_dsconfig_19}" "${post_dsreplication_dsconfig_20}" "${post_dsreplication_dsconfig_21}" "${post_dsreplication_dsconfig_22}" "${post_dsreplication_dsconfig_23}" "${post_dsreplication_dsconfig_24}" "${post_dsreplication_dsconfig_25}" "${post_dsreplication_dsconfig_26}" "${post_dsreplication_dsconfig_27}" "${post_dsreplication_dsconfig_28}" "${post_dsreplication_dsconfig_29}" "${post_dsreplication_dsconfig_30}" "${post_dsreplication_dsconfig_31}" "${post_dsreplication_dsconfig_32}" "${post_dsreplication_dsconfig_33}" "${post_dsreplication_dsconfig_34}" "${post_dsreplication_dsconfig_35}" "${post_dsreplication_dsconfig_36}" "${post_dsreplication_dsconfig_37}" "${post_dsreplication_dsconfig_38}" "${post_dsreplication_dsconfig_39}" "${post_dsreplication_dsconfig_40}" "${post_dsreplication_dsconfig_41}" "${post_dsreplication_dsconfig_42}" "${post_dsreplication_dsconfig_43}" "${post_dsreplication_dsconfig_44}" "${post_dsreplication_dsconfig_45}" "${post_dsreplication_dsconfig_46}" "${post_dsreplication_dsconfig_47}" "${post_dsreplication_dsconfig_48}" "${post_dsreplication_dsconfig_49}" "${post_dsreplication_dsconfig_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${post_dsreplication_dsconfigParam}" ]
	then
	  echo -n "post_dsreplication_dsconfig_${i} [${post_dsreplication_dsconfigParam}] "
    fi
  done
  echo ""
}

post_dsreplication_dsconfig() {
  if [ -z "${post_dsreplication_dsconfig_1}" ]
  then
    return
  fi		

  echo "[$(date)] - Executing post_dsreplication_dsconfig commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
  # Before invoking dsconfig command, let's wait for port to be accessible
  waitForServerPort ${hostname} ${adminConnectorPort}
  waitForSourceServerPorts "${sourceServerPorts}"
  
  for dsconfigParam in "${post_dsreplication_dsconfig_1}" "${post_dsreplication_dsconfig_2}" "${post_dsreplication_dsconfig_3}" "${post_dsreplication_dsconfig_4}" "${post_dsreplication_dsconfig_5}" "${post_dsreplication_dsconfig_6}" "${post_dsreplication_dsconfig_7}" "${post_dsreplication_dsconfig_8}" "${post_dsreplication_dsconfig_9}" "${post_dsreplication_dsconfig_10}" "${post_dsreplication_dsconfig_11}" "${post_dsreplication_dsconfig_12}" "${post_dsreplication_dsconfig_13}" "${post_dsreplication_dsconfig_14}" "${post_dsreplication_dsconfig_15}" "${post_dsreplication_dsconfig_16}" "${post_dsreplication_dsconfig_17}" "${post_dsreplication_dsconfig_18}" "${post_dsreplication_dsconfig_19}" "${post_dsreplication_dsconfig_20}" "${post_dsreplication_dsconfig_21}" "${post_dsreplication_dsconfig_22}" "${post_dsreplication_dsconfig_23}" "${post_dsreplication_dsconfig_24}" "${post_dsreplication_dsconfig_25}" "${post_dsreplication_dsconfig_26}" "${post_dsreplication_dsconfig_27}" "${post_dsreplication_dsconfig_28}" "${post_dsreplication_dsconfig_29}" "${post_dsreplication_dsconfig_30}" "${post_dsreplication_dsconfig_31}" "${post_dsreplication_dsconfig_32}" "${post_dsreplication_dsconfig_33}" "${post_dsreplication_dsconfig_34}" "${post_dsreplication_dsconfig_35}" "${post_dsreplication_dsconfig_36}" "${post_dsreplication_dsconfig_37}" "${post_dsreplication_dsconfig_38}" "${post_dsreplication_dsconfig_39}" "${post_dsreplication_dsconfig_40}" "${post_dsreplication_dsconfig_41}" "${post_dsreplication_dsconfig_42}" "${post_dsreplication_dsconfig_43}" "${post_dsreplication_dsconfig_44}" "${post_dsreplication_dsconfig_45}" "${post_dsreplication_dsconfig_46}" "${post_dsreplication_dsconfig_47}" "${post_dsreplication_dsconfig_48}" "${post_dsreplication_dsconfig_49}" "${post_dsreplication_dsconfig_50}"
  do
	if [ ! -z "${dsconfigParam}" ]
	then	 
      updatedParam=$(echo ${dsconfigParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
  	  echo "[$(date)] - Executing post_dsreplication_dsconfig with parameters ${dsconfigParam} -> ${updatedParam}"
	  dsconfigParam=${updatedParam}
	  if [[ ${dsconfigParam} =~ "set-replication-" ]]
	  then
		echo "[$(date)] - Additionally adding --provider-name \"Multimaster Synchronizatin\""
        echo eval ${OUD_INST_HOME}/bin/dsconfig \
    	    --no-prompt \
            --hostname ${hostname} \
            --port ${adminConnectorPort} \
    	    --bindDN '"${rootUserDN}"' \
    	    --bindPasswordFile ${rootPwdFile} \
    	    --trustAll \
  		    ${dsconfigParam} --provider-name '"Multimaster Synchronization"' >> ${dsconfigCmdLogs}
  
        eval ${OUD_INST_HOME}/bin/dsconfig \
    	    --no-prompt \
            --hostname ${hostname} \
            --port ${adminConnectorPort} \
    	    --bindDN '"${rootUserDN}"' \
    	    --bindPasswordFile ${rootPwdFile} \
    	    --trustAll \
    	    ${dsconfigParam} --provider-name '"Multimaster Synchronization"' > ${dsconfigCmdLogs}.tmp 2>&1
        execStatus=$?
		cat ${dsconfigCmdLogs}.tmp | tee -a ${dsconfigCmdLogs}
        echo "[$(date)] - execStatus [${execStatus}]"
        if [ ${execStatus} -gt 0 -a "${ignoreErrorPostDsreplDsconfig}" = "false" ]
        then
          echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorPostDsreplDsconfig=false, exiting ..."
          exit 1
        fi
	  else
        echo eval ${OUD_INST_HOME}/bin/dsconfig \
    	    --no-prompt \
            --hostname ${hostname} \
            --port ${adminConnectorPort} \
    	    --bindDN '"${rootUserDN}"' \
    	    --bindPasswordFile ${rootPwdFile} \
    	    --trustAll \
  		${dsconfigParam} >> ${dsconfigCmdLogs}
  
        eval ${OUD_INST_HOME}/bin/dsconfig \
    	    --no-prompt \
            --hostname ${hostname} \
            --port ${adminConnectorPort} \
    	    --bindDN '"${rootUserDN}"' \
    	    --bindPasswordFile ${rootPwdFile} \
    	    --trustAll \
    	    ${dsconfigParam} > ${dsconfigCmdLogs}.tmp 2>&1
        execStatus=$?
		cat ${dsconfigCmdLogs}.tmp | tee -a ${dsconfigCmdLogs}
        echo "[$(date)] - execStatus [${execStatus}]"
        if [ ${execStatus} -gt 0 -a "${ignoreErrorPostDsreplDsconfig}" = "false" ]
        then
          echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorPostDsreplDsconfig=false, exiting ..."
          exit 1
        fi
      fi 		  
	fi
  done
  echo "[$(date)] - Executed all configured post_dsreplication_dsconfig commands." 2>&1 | tee -a ${oudInstanceConfigStatus}
  if [ "${restartAfterPostDsreplDsconfig}" = "true" ]
  then
    restartOUD
  fi
}

############ dsreplication ###########

checkBeforeDsreplicationExecution() {
  if [ "${hostname}" != "${sourceHost}" ]
  then
	waitForServerPort ${sourceHost} ${sourceAdminConnectorPort}
  fi
  if [ "${sourceHost}" != "${initializeFromHost}" ]
  then
    waitForServerPort ${initializeFromHost} ${sourceAdminConnectorPort}
  fi
  waitForServerPort ${hostname} ${adminConnectorPort}
  waitForSourceServerPorts "${sourceServerPorts}"
}

printDsreplicationParams() {
  i=0
  echo -n "dsreplication Parameters: "	
  for dsreplicationParam in "${dsreplication_1}" "${dsreplication_2}" "${dsreplication_3}" "${dsreplication_4}" "${dsreplication_5}" "${dsreplication_6}" "${dsreplication_7}" "${dsreplication_8}" "${dsreplication_9}" "${dsreplication_10}" "${dsreplication_11}" "${dsreplication_12}" "${dsreplication_13}" "${dsreplication_14}" "${dsreplication_15}" "${dsreplication_16}" "${dsreplication_17}" "${dsreplication_18}" "${dsreplication_19}" "${dsreplication_20}" "${dsreplication_21}" "${dsreplication_22}" "${dsreplication_23}" "${dsreplication_24}" "${dsreplication_25}" "${dsreplication_26}" "${dsreplication_27}" "${dsreplication_28}" "${dsreplication_29}" "${dsreplication_30}" "${dsreplication_31}" "${dsreplication_32}" "${dsreplication_33}" "${dsreplication_34}" "${dsreplication_35}" "${dsreplication_36}" "${dsreplication_37}" "${dsreplication_38}" "${dsreplication_39}" "${dsreplication_40}" "${dsreplication_41}" "${dsreplication_42}" "${dsreplication_43}" "${dsreplication_44}" "${dsreplication_45}" "${dsreplication_46}" "${dsreplication_47}" "${dsreplication_48}" "${dsreplication_49}" "${dsreplication_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${dsreplicationParam}" ]
	then
	  echo -n "dsreplication_${i} [${dsreplicationParam}] "
    fi
  done
  echo ""
}

dsReplication() {
  if [ -z "${dsreplication_1}" ]
  then
    return
  fi		

  echo "[$(date)] - Executing dsreplication commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
  checkBeforeDsreplicationExecution
  for dsreplicationParam in "${dsreplication_1}" "${dsreplication_2}" "${dsreplication_3}" "${dsreplication_4}" "${dsreplication_5}" "${dsreplication_6}" "${dsreplication_7}" "${dsreplication_8}" "${dsreplication_9}" "${dsreplication_10}" "${dsreplication_11}" "${dsreplication_12}" "${dsreplication_13}" "${dsreplication_14}" "${dsreplication_15}" "${dsreplication_16}" "${dsreplication_17}" "${dsreplication_18}" "${dsreplication_19}" "${dsreplication_20}" "${dsreplication_21}" "${dsreplication_22}" "${dsreplication_23}" "${dsreplication_24}" "${dsreplication_25}" "${dsreplication_26}" "${dsreplication_27}" "${dsreplication_28}" "${dsreplication_29}" "${dsreplication_30}" "${dsreplication_31}" "${dsreplication_32}" "${dsreplication_33}" "${dsreplication_34}" "${dsreplication_35}" "${dsreplication_36}" "${dsreplication_37}" "${dsreplication_38}" "${dsreplication_39}" "${dsreplication_40}"
  do
	if [ ! -z "${dsreplicationParam}" ]
	then	 
	  # updatedParam=$(echo ${dsreplicationParam} \
	  # 		 | sed \
	  # 		 -e "s|\-\-bindDN1\ |\-\-bindDN1\ \"${bindDN1}\"\ \-\-bindPasswordFile1\ ${bindPwdFile1}\ |g" \
	  # 		 -e "s|\-\-bindDN2\ |\-\-bindDN2\ \"${bindDN2}\"\ \-\-bindPasswordFile2\ ${bindPwdFile2}\ |g" \
	  # 		 -e "s|\-\-adminUID\ |\-\-adminUID\ \"${adminUID}\"\ \-\-adminPasswordFile\ ${adminPwdFile}\ |g" \
	  # 			  )
      updatedParam=$(echo ${dsreplicationParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
	  echo "[$(date)] - Executing dsreplication with parameters ${dsreplicationParam} -> ${updatedParam}"
	  dsreplicationParam=${updatedParam}
	  checkBeforeDsreplicationExecution
	  execStatus=0
	  if [[ ${dsreplicationParam} =~ "enable " ]]
	  then
		echo "[$(date)] - Executing dsreplication enable with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --bindDN1 (value from env variable bindDN1), --bindPasswordFile1 (file containing value from env variable bindPassword1), --bindDN2 (value from env variable bindDN2), --bindPasswordFile2 (file containing value from env variable bindPassword2), --adminUID (value from env variable adminUID), and --adminPasswordFile (file containing value from env variable adminPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --bindDN1 "${bindDN1}" \
  		    --bindPasswordFile1 ${bindPwdFile1} \
  		    --bindDN2 "${bindDN2}" \
  		    --bindPasswordFile2 ${bindPwdFile2} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --bindDN1 "${bindDN1}" \
  		    --bindPasswordFile1 ${bindPwdFile1} \
  		    --bindDN2 "${bindDN2}" \
  		    --bindPasswordFile2 ${bindPwdFile2} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "disable " ]]
	  then
	    echo "[$(date)] - Executing dsreplication disable with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --adminUID (value from env variable adminUID), and --adminPasswordFile (file containing value from env variable adminPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "disable-changelog " ]]
	  then
	    echo "[$(date)] - Executing dsreplication disable-changelog with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --bindDN (value from env variable rootUserDN), --bindPasswordFile (file containing value from env variable rootUserPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --bindDN "${rootUserDN}" \
  		    --bindPasswordFile ${rootPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --bindDN "${rootUserDN}" \
  		    --bindPasswordFile ${rootPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "enable-changelog " ]]
	  then
	    echo "[$(date)] - Executing dsreplication enable-changelog with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --bindDN (value from env variable rootUserDN), --bindPasswordFile (file containing value from env variable rootUserPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --bindDN "${rootUserDN}" \
  		    --bindPasswordFile ${rootPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --bindDN "${rootUserDN}" \
  		    --bindPasswordFile ${rootPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "initialize " ]]
	  then
	    echo "[$(date)] - Executing dsreplication initialize with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --adminUID (value from env variable adminUID), and --adminPasswordFile (file containing value from env variable adminPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
 	  elif [[ ${dsreplicationParam} =~ "initialize-all " ]]
	  then
	    echo "[$(date)] - Executing dsreplication initialize-all with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --adminUID (value from env variable adminUID), and --adminPasswordFile (file containing value from env variable adminPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "status " ]]
	  then
	    echo "[$(date)] - Executing dsreplication status with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --adminUID (value from env variable adminUID), and --adminPasswordFile (file containing value from env variable adminPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "verify " ]]
	  then
	    echo "[$(date)] - Executing dsreplication verify with parameters ${dsreplicationParam}"
		echo "[$(date)] - Additionally adding --adminUID (value from env variable adminUID), and --adminPasswordFile (file containing value from env variable adminPassword)"
        echo ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll >> ${dsreplicationCmdLogs}
        ${OUD_INST_HOME}/bin/dsreplication \
    		${dsreplicationParam} \
  		    --adminUID "${adminUID}" \
  		    --adminPasswordFile ${adminPwdFile} \
    	    --no-prompt \
    	    --trustAll > ${dsreplicationCmdLogs}.tmp 2>&1
		execStatus=$?
		cat ${dsreplicationCmdLogs}.tmp | tee -a ${dsreplicationCmdLogs}
	  elif [[ ${dsreplicationParam} =~ "post-external-inialization " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication post-external-inialization with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  elif [[ ${dsreplicationParam} =~ "pre-external-initialization " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication pre-external-initialization with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  elif [[ ${dsreplicationParam} =~ "purge-historical " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication purge-historical with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  elif [[ ${dsreplicationParam} =~ "list-certs " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication list-certs with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  elif [[ ${dsreplicationParam} =~ "regenerate-cert " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication regenerate-cert with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  elif [[ ${dsreplicationParam} =~ "set-cert " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication set-cert with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  elif [[ ${dsreplicationParam} =~ "set-trust " ]]
	  then
	    echo "[$(date)] - Yet, Execution of dsreplication set-trust with parameters ${dsreplicationParam} is not supported. This line of paramters will be ignored."
	  else
		echo "[$(date)] - dsreplication parameters [${dsreplicationParam}] are not looking valid. This line of paramters will be ignored."
	  fi
      echo "[$(date)] - execStatus [${execStatus}]"
      if [ ${execStatus} -gt 0 -a "${ignoreErrorDsreplication}" = "false" ]
      then
        echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorDsreplication=false, exiting ..."
        exit 1
      fi
	fi 
  done
  echo "[$(date)] - Executed all configured dsreplication commands"  2>&1 | tee -a ${oudInstanceConfigStatus}
  if [ "${restartAfterDsreplication}" = "true" ]
  then
    restartOUD
  fi
}

# Function to Support Java security Input option
java_security_config()
{
  if [ -f "${javaSecurityFile}" ]
  then
    diffCount=$(diff $JAVA_HOME/jre/lib/security/java.security ${javaSecurityFile} | wc -l)
    if [ ${diffCount} -ne 0 ]
    then
      echo "[$(date)] - There is a difference between $JAVA_HOME/jre/lib/security/java.security and ${javaSecurityFile} "
      cp $JAVA_HOME/jre/lib/security/java.security $OUD_ADMIN_DIR/java.security.old
      cp ${javaSecurityFile} $JAVA_HOME/jre/lib/security/java.security
	  echo "[$(date)] - Setting the flag for restarting OUD Instance to have java.security parameters in affect" 
	  export restartOUDInstAfterConfig=true
      if [ "${restartAfterJavaSecurityFile}" = "true" ]
      then
        restartOUDInstAfterConfig=false
        restartOUD
      fi
    fi
  fi
}


# Functions to support Data/Schema input
printSchemaConfigParams() {
  i=0
  echo -n "schemaConfigFile Parameters: "	
  for schemaConfigFileParam in "${schemaConfigFile_1}" "${schemaConfigFile_2}" "${schemaConfigFile_3}" "${schemaConfigFile_4}" "${schemaConfigFile_5}" "${schemaConfigFile_6}" "${schemaConfigFile_7}" "${schemaConfigFile_8}" "${schemaConfigFile_9}" "${schemaConfigFile_10}" "${schemaConfigFile_11}" "${schemaConfigFile_12}" "${schemaConfigFile_13}" "${schemaConfigFile_14}" "${schemaConfigFile_15}" "${schemaConfigFile_16}" "${schemaConfigFile_17}" "${schemaConfigFile_18}" "${schemaConfigFile_19}" "${schemaConfigFile_20}" "${schemaConfigFile_21}" "${schemaConfigFile_22}" "${schemaConfigFile_23}" "${schemaConfigFile_24}" "${schemaConfigFile_25}" "${schemaConfigFile_26}" "${schemaConfigFile_27}" "${schemaConfigFile_28}" "${schemaConfigFile_29}" "${schemaConfigFile_30}" "${schemaConfigFile_31}" "${schemaConfigFile_32}" "${schemaConfigFile_33}" "${schemaConfigFile_34}" "${schemaConfigFile_35}" "${schemaConfigFile_36}" "${schemaConfigFile_37}" "${schemaConfigFile_38}" "${schemaConfigFile_39}" "${schemaConfigFile_40}" "${schemaConfigFile_41}" "${schemaConfigFile_42}" "${schemaConfigFile_43}" "${schemaConfigFile_44}" "${schemaConfigFile_45}" "${schemaConfigFile_46}" "${schemaConfigFile_47}" "${schemaConfigFile_48}" "${schemaConfigFile_49}" "${schemaConfigFile_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${schemaConfigFileParam}" ]
	then
	  echo -n "schemaConfigFile_${i} [${schemaConfigFileParam}] "
    fi
  done
  echo ""
}


schemaConfig()
{
  if [ -f "${schemaConfigFile_1}" ]
  then
    target_folder="${OUD_INST_HOME}/config/schema/"
    echo "[$(date)] -  Executing Schema config to apply the input schema files " 2>&1 | tee -a ${oudInstanceConfigStatus}

    for schemaConfigParam in "${schemaConfigFile_1}" "${schemaConfigFile_2}" "${schemaConfigFile_3}" "${schemaConfigFile_4}" "${schemaConfigFile_5}" "${schemaConfigFile_6}" "${schemaConfigFile_7}" "${schemaConfigFile_8}" "${schemaConfigFile_9}" "${schemaConfigFile_10}" "${schemaConfigFile_11}" "${schemaConfigFile_12}" "${schemaConfigFile_13}" "${schemaConfigFile_14}" "${schemaConfigFile_15}" "${schemaConfigFile_16}" "${schemaConfigFile_17}" "${schemaConfigFile_18}" "${schemaConfigFile_19}" "${schemaConfigFile_20}" "${schemaConfigFile_21}" "${schemaConfigFile_22}" "${schemaConfigFile_23}" "${schemaConfigFile_24}" "${schemaConfigFile_25}" "${schemaConfigFile_26}" "${schemaConfigFile_27}" "${schemaConfigFile_28}" "${schemaConfigFile_29}" "${schemaConfigFile_30}" "${schemaConfigFile_31}" "${schemaConfigFile_32}" "${schemaConfigFile_33}" "${schemaConfigFile_34}" "${schemaConfigFile_35}" "${schemaConfigFile_36}" "${schemaConfigFile_37}" "${schemaConfigFile_38}" "${schemaConfigFile_39}" "${schemaConfigFile_40}" "${schemaConfigFile_41}" "${schemaConfigFile_42}" "${schemaConfigFile_43}" "${schemaConfigFile_44}" "${schemaConfigFile_45}" "${schemaConfigFile_46}" "${schemaConfigFile_47}" "${schemaConfigFile_48}" "${schemaConfigFile_49}" "${schemaConfigFile_50}"
    do
      if [ ! -z "${schemaConfigParam}" -a -f "${schemaConfigParam}" ]
      then
		# If file contains changeType: modify, let's try to load schema using ldapmodify
		# else file can be copied to config/schema folder
		changeTypeModCnt=$(grep -i "changetype: modify" "${schemaConfigParam}" | wc -l)
		if [ ${changeTypeModCnt} -gt 0 ]
		then
		  # Load Schema file using ldapmodify
		  echo "[$(date)] - ${schemaConfigParam} contains 'changeType: modify'. So, schema changes would be loaded using ldapmodify"
          echo ${OUD_INST_HOME}/bin/ldapmodify \
            --hostname ${hostname} \
            --port ${adminConnectorPort} \
      	    --bindDN "${rootUserDN}" \
      	    --bindPasswordFile ${rootPwdFile} \
			--useSSL \
      	    --trustAll \
			--filename ${schemaConfigParam}
          ${OUD_INST_HOME}/bin/ldapmodify \
            --hostname ${hostname} \
            --port ${adminConnectorPort} \
      	    --bindDN "${rootUserDN}" \
      	    --bindPasswordFile ${rootPwdFile} \
			--useSSL \
      	    --trustAll \
			--filename ${schemaConfigParam}
          execStatus=$?
          echo "[$(date)] - execStatus [${execStatus}]"
          if [ ${execStatus} -gt 0 -a "${ignoreErrorSchemaConfig}" = "false" ]
          then
            echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorSchemaConfig=false, exiting ..."
            exit 1
          fi		
		else
          filename=$(basename "${schemaConfigParam}" "")
          if [ -f "${target_folder}/${filename}" ]
          then
            diff_Count=$(diff ${schemaConfigParam} ${target_folder}/${filename} | wc -l)
            if [ ${diff_Count} -ne 0 ]
            then
              echo "[$(date)] - Copying the schema file ${schemaConfigParam}"
              cp ${schemaConfigParam} ${target_folder}
            fi
          else
            echo "[$(date)] - Copying the schema file ${schemaConfigParam}"
            cp ${schemaConfigParam} ${target_folder}
          fi
		fi  
      fi
    done
	echo "[$(date)] - Executed all Schema config" 2>&1 | tee -a ${oudInstanceConfigStatus}
	export restartOUDInstAfterConfig=true
    if [ "${restartAfterSchemaConfig}" = "true" ]
    then
      restartOUDInstAfterConfig=false
      restartOUD
    fi
  fi
}

# Functions for rebuild-index command 
printRebuildIndexParams() {
  i=0
  echo -n "rebuildIndex Parameters: "	
  for rebuildIndexParam in "${rebuildIndex_1}" "${rebuildIndex_2}" "${rebuildIndex_3}" "${rebuildIndex_4}" "${rebuildIndex_5}" "${rebuildIndex_6}" "${rebuildIndex_7}" "${rebuildIndex_8}" "${rebuildIndex_9}" "${rebuildIndex_10}" "${rebuildIndex_11}" "${rebuildIndex_12}" "${rebuildIndex_13}" "${rebuildIndex_14}" "${rebuildIndex_15}" "${rebuildIndex_16}" "${rebuildIndex_17}" "${rebuildIndex_18}" "${rebuildIndex_19}" "${rebuildIndex_20}" "${rebuildIndex_21}" "${rebuildIndex_22}" "${rebuildIndex_23}" "${rebuildIndex_24}" "${rebuildIndex_25}" "${rebuildIndex_26}" "${rebuildIndex_27}" "${rebuildIndex_28}" "${rebuildIndex_29}" "${rebuildIndex_30}" "${rebuildIndex_31}" "${rebuildIndex_32}" "${rebuildIndex_33}" "${rebuildIndex_34}" "${rebuildIndex_35}" "${rebuildIndex_36}" "${rebuildIndex_37}" "${rebuildIndex_38}" "${rebuildIndex_39}" "${rebuildIndex_40}" "${rebuildIndex_41}" "${rebuildIndex_42}" "${rebuildIndex_43}" "${rebuildIndex_44}" "${rebuildIndex_45}" "${rebuildIndex_46}" "${rebuildIndex_47}" "${rebuildIndex_48}" "${rebuildIndex_49}" "${rebuildIndex_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${rebuildIndexParam}" ]
	then
	  echo -n "rebuildIndex_${i} [${rebuildIndexParam}] "
    fi
  done
  echo ""
}

rebuildIndex() {
  if [ -z "${rebuildIndex_1}" ]
  then
    return
  fi		
  echo "[$(date)] - Executing rebuildIndex commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo "[$(date)] - Before running rebuildIndex command(s), let's check the status"
  ${SCRIPT_DIR}/checkOUDInstance.sh
  checkOudError=$?
  if [ ${checkOudError} -gt 0 ]; then
    echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
  fi

  # Before invoking rebuildIndex command, let's wait for port to be accessible
  waitForServerPort ${hostname} ${adminConnectorPort}
  
  for rebuildIndexParam in "${rebuildIndex_1}" "${rebuildIndex_2}" "${rebuildIndex_3}" "${rebuildIndex_4}" "${rebuildIndex_5}" "${rebuildIndex_6}" "${rebuildIndex_7}" "${rebuildIndex_8}" "${rebuildIndex_9}" "${rebuildIndex_10}" "${rebuildIndex_11}" "${rebuildIndex_12}" "${rebuildIndex_13}" "${rebuildIndex_14}" "${rebuildIndex_15}" "${rebuildIndex_16}" "${rebuildIndex_17}" "${rebuildIndex_18}" "${rebuildIndex_19}" "${rebuildIndex_20}" "${rebuildIndex_21}" "${rebuildIndex_22}" "${rebuildIndex_23}" "${rebuildIndex_24}" "${rebuildIndex_25}" "${rebuildIndex_26}" "${rebuildIndex_27}" "${rebuildIndex_28}" "${rebuildIndex_29}" "${rebuildIndex_30}" "${rebuildIndex_31}" "${rebuildIndex_32}" "${rebuildIndex_33}" "${rebuildIndex_34}" "${rebuildIndex_35}" "${rebuildIndex_36}" "${rebuildIndex_37}" "${rebuildIndex_38}" "${rebuildIndex_39}" "${rebuildIndex_40}" "${rebuildIndex_41}" "${rebuildIndex_42}" "${rebuildIndex_43}" "${rebuildIndex_44}" "${rebuildIndex_45}" "${rebuildIndex_46}" "${rebuildIndex_47}" "${rebuildIndex_48}" "${rebuildIndex_49}" "${rebuildIndex_50}"
  do
	if [ ! -z "${rebuildIndexParam}" ]
	then	 
      updatedParam=$(echo ${rebuildIndexParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
  	  echo "[$(date)] - Executing rebuildIndex with parameters ${rebuildIndexParam} -> ${updatedParam}"
	  rebuildIndexParam=${updatedParam}
      echo ${OUD_INST_HOME}/bin/rebuild-index \
        --hostname ${hostname} \
        --port ${adminConnectorPort} \
  	    --bindDN "${rootUserDN}" \
  	    --bindPasswordFile ${rootPwdFile} \
		--baseDN ${baseDN} \
  	    --trustAll \
		${rebuildIndexParam} >> ${rebuildIndexCmdLogs}

      ${OUD_INST_HOME}/bin/rebuild-index \
        --hostname ${hostname} \
        --port ${adminConnectorPort} \
  	    --bindDN "${rootUserDN}" \
  	    --bindPasswordFile ${rootPwdFile} \
		--baseDN ${baseDN} \
  	    --trustAll \
  	    ${rebuildIndexParam} > ${rebuildIndexCmdLogs}.tmp 2>&1
      execStatus=$?
	  cat ${rebuildIndexCmdLogs}.tmp | tee -a ${rebuildIndexCmdLogs}
      echo "[$(date)] - execStatus [${execStatus}]"
      if [ ${execStatus} -gt 0 -a "${ignoreErrorRebuildIndex}" = "false" ]
      then
        echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorRebuildIndex=false, exiting ..."
        exit 1
      fi
	fi
  done
  echo "[$(date)] - Executed all configured rebuildIndex commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
  if [ "${restartAfterRebuildIndex}" = "true" ]
  then
    restartOUD
  fi
}

# Functions for manage-suffix commands 
printManageSuffixParams() {
  i=0
  echo -n "manageSuffix Parameters: "	
  for manageSuffixParam in "${manageSuffix_1}" "${manageSuffix_2}" "${manageSuffix_3}" "${manageSuffix_4}" "${manageSuffix_5}" "${manageSuffix_6}" "${manageSuffix_7}" "${manageSuffix_8}" "${manageSuffix_9}" "${manageSuffix_10}" "${manageSuffix_11}" "${manageSuffix_12}" "${manageSuffix_13}" "${manageSuffix_14}" "${manageSuffix_15}" "${manageSuffix_16}" "${manageSuffix_17}" "${manageSuffix_18}" "${manageSuffix_19}" "${manageSuffix_20}" "${manageSuffix_21}" "${manageSuffix_22}" "${manageSuffix_23}" "${manageSuffix_24}" "${manageSuffix_25}" "${manageSuffix_26}" "${manageSuffix_27}" "${manageSuffix_28}" "${manageSuffix_29}" "${manageSuffix_30}" "${manageSuffix_31}" "${manageSuffix_32}" "${manageSuffix_33}" "${manageSuffix_34}" "${manageSuffix_35}" "${manageSuffix_36}" "${manageSuffix_37}" "${manageSuffix_38}" "${manageSuffix_39}" "${manageSuffix_40}" "${manageSuffix_41}" "${manageSuffix_42}" "${manageSuffix_43}" "${manageSuffix_44}" "${manageSuffix_45}" "${manageSuffix_46}" "${manageSuffix_47}" "${manageSuffix_48}" "${manageSuffix_49}" "${manageSuffix_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${manageSuffixParam}" ]
	then
	  echo -n "manageSuffix_${i} [${manageSuffixParam}] "
    fi
  done
  echo ""
}

manageSuffix() {
    if [ -z "${manageSuffix_1}" ]
    then
      return
    fi

	echo "[$(date)] - Executing manage-suffix commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
    echo "[$(date)] - Executing manage-suffix commands" >> ${manageSuffixCmdLogs}
    echo "[$(date)] - Before running manageSuffix command(s), let's check the status" >> ${manageSuffixCmdLogs}
    ${SCRIPT_DIR}/checkOUDInstance.sh
    checkOudError=$?
    if [ ${checkOudError} -gt 0 ]; then
      echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
      exit 1
    fi
    
    for manageSuffixParam in "${manageSuffix_1}" "${manageSuffix_2}" "${manageSuffix_3}" "${manageSuffix_4}" "${manageSuffix_5}" "${manageSuffix_6}" "${manageSuffix_7}" "${manageSuffix_8}" "${manageSuffix_9}" "${manageSuffix_10}" "${manageSuffix_11}" "${manageSuffix_12}" "${manageSuffix_13}" "${manageSuffix_14}" "${manageSuffix_15}" "${manageSuffix_16}" "${manageSuffix_17}" "${manageSuffix_18}" "${manageSuffix_19}" "${manageSuffix_20}" "${manageSuffix_21}" "${manageSuffix_22}" "${manageSuffix_23}" "${manageSuffix_24}" "${manageSuffix_25}" "${manageSuffix_26}" "${manageSuffix_27}" "${manageSuffix_28}" "${manageSuffix_29}" "${manageSuffix_30}" "${manageSuffix_31}" "${manageSuffix_32}" "${manageSuffix_33}" "${manageSuffix_34}" "${manageSuffix_35}" "${manageSuffix_36}" "${manageSuffix_37}" "${manageSuffix_38}" "${manageSuffix_39}" "${manageSuffix_40}" "${manageSuffix_41}" "${manageSuffix_42}" "${manageSuffix_43}" "${manageSuffix_44}" "${manageSuffix_45}" "${manageSuffix_46}" "${manageSuffix_47}" "${manageSuffix_48}" "${manageSuffix_49}" "${manageSuffix_50}"
    do
      if [ ! -z "${manageSuffixParam}" ]
      then
		updatedParam=$(echo ${manageSuffixParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
        echo "[$(date)] - Executing manageSuffix with parameters ${manageSuffixParam} -> ${updatedParam}" 2>&1 | tee -a ${manageSuffixCmdLogs}
        manageSuffixParam=${updatedParam}
        echo ${OUD_INST_HOME}/bin/manage-suffix \
             --hostname ${hostname} \
             --port ${adminConnectorPort} \
  	         --bindDN "${rootUserDN}" \
  	         --bindPasswordFile ${rootPwdFile} \
  	         --trustAll \
             ${manageSuffixParam} \
             --no-prompt  >> ${manageSuffixCmdLogs}
        ${OUD_INST_HOME}/bin/manage-suffix \
             --hostname ${hostname} \
             --port ${adminConnectorPort} \
  	         --bindDN "${rootUserDN}" \
  	         --bindPasswordFile ${rootPwdFile} \
  	         --trustAll \
             ${manageSuffixParam} \
             --no-prompt > ${manageSuffixCmdLogs}.tmp 2>&1
        execStatus=$?
		cat ${manageSuffixCmdLogs}.tmp | tee -a ${manageSuffixCmdLogs}
        echo "[$(date)] - execStatus [${execStatus}]"
        if [ ${execStatus} -gt 0 -a "${ignoreErrorManageSuffix}" = "false" ]
        then
          echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorManageSuffix=false, exiting ..."
          exit 1
        fi
      fi
    done
	echo "[$(date)] - Executed all configured manage-suffix commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
    if [ "${restartAfterManageSuffix}" = "true" ]
    then
      restartOUD
    fi
}

# Functions for import-ldif commands 
printImportLdifParams() {
  i=0
  echo -n "importLdif Parameters: "	
  for importLdifParam in "${importLdif_1}" "${importLdif_2}" "${importLdif_3}" "${importLdif_4}" "${importLdif_5}" "${importLdif_6}" "${importLdif_7}" "${importLdif_8}" "${importLdif_9}" "${importLdif_10}" "${importLdif_11}" "${importLdif_12}" "${importLdif_13}" "${importLdif_14}" "${importLdif_15}" "${importLdif_16}" "${importLdif_17}" "${importLdif_18}" "${importLdif_19}" "${importLdif_20}" "${importLdif_21}" "${importLdif_22}" "${importLdif_23}" "${importLdif_24}" "${importLdif_25}" "${importLdif_26}" "${importLdif_27}" "${importLdif_28}" "${importLdif_29}" "${importLdif_30}" "${importLdif_31}" "${importLdif_32}" "${importLdif_33}" "${importLdif_34}" "${importLdif_35}" "${importLdif_36}" "${importLdif_37}" "${importLdif_38}" "${importLdif_39}" "${importLdif_40}" "${importLdif_41}" "${importLdif_42}" "${importLdif_43}" "${importLdif_44}" "${importLdif_45}" "${importLdif_46}" "${importLdif_47}" "${importLdif_48}" "${importLdif_49}" "${importLdif_50}"
  do
	i=$(expr $i + 1)
	if [ ! -z "${importLdifParam}" ]
	then
	  echo -n "importLdif_${i} [${importLdifParam}] "
    fi
  done
  echo ""
}

importLdif() {
    if [ -z "${importLdif_1}" ]
    then
      return
    fi

	echo "[$(date)] - Executing importLdif commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
    echo "[$(date)] - Executing importLdif commands" >> ${importLdifCmdLogs}
    echo "[$(date)] - Before running importLdif command(s), let's check the status" >> ${importLdifCmdLogs}
    ${SCRIPT_DIR}/checkOUDInstance.sh
    checkOudError=$?
    if [ ${checkOudError} -gt 0 ]; then
      echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
      exit 1
    fi
    
    for importLdifParam in "${importLdif_1}" "${importLdif_2}" "${importLdif_3}" "${importLdif_4}" "${importLdif_5}" "${importLdif_6}" "${importLdif_7}" "${importLdif_8}" "${importLdif_9}" "${importLdif_10}" "${importLdif_11}" "${importLdif_12}" "${importLdif_13}" "${importLdif_14}" "${importLdif_15}" "${importLdif_16}" "${importLdif_17}" "${importLdif_18}" "${importLdif_19}" "${importLdif_20}" "${importLdif_21}" "${importLdif_22}" "${importLdif_23}" "${importLdif_24}" "${importLdif_25}" "${importLdif_26}" "${importLdif_27}" "${importLdif_28}" "${importLdif_29}" "${importLdif_30}" "${importLdif_31}" "${importLdif_32}" "${importLdif_33}" "${importLdif_34}" "${importLdif_35}" "${importLdif_36}" "${importLdif_37}" "${importLdif_38}" "${importLdif_39}" "${importLdif_40}" "${importLdif_41}" "${importLdif_42}" "${importLdif_43}" "${importLdif_44}" "${importLdif_45}" "${importLdif_46}" "${importLdif_47}" "${importLdif_48}" "${importLdif_49}" "${importLdif_50}"
    do
      if [ ! -z "${importLdifParam}" ]
      then
		updatedParam=$(echo ${importLdifParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
        echo "[$(date)] - Executing importLdif with parameters ${importLdifParam} -> ${updatedParam}" 2>&1 | tee -a ${importLdifCmdLogs}
        importLdifParam=${updatedParam}
        echo ${OUD_INST_HOME}/bin/import-ldif \
             --hostname ${hostname} \
             --port ${adminConnectorPort} \
  	         --bindDN "${rootUserDN}" \
  	         --bindPasswordFile ${rootPwdFile} \
  	         --trustAll \
             ${importLdifParam} >> ${importLdifCmdLogs}
        ${OUD_INST_HOME}/bin/import-ldif \
             --hostname ${hostname} \
             --port ${adminConnectorPort} \
  	         --bindDN "${rootUserDN}" \
  	         --bindPasswordFile ${rootPwdFile} \
  	         --trustAll \
             ${importLdifParam} > ${importLdifCmdLogs}.tmp 2>&1
        execStatus=$?
		cat ${importLdifCmdLogs}.tmp | tee -a ${importLdifCmdLogs}
        echo "[$(date)] - execStatus [${execStatus}]"
        if [ ${execStatus} -gt 0 -a "${ignoreErrorImportLdif}" = "false" ]
        then
          echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorImportLdif=false, exiting ..."
          exit 1
        fi
      fi
    done
	echo "[$(date)] - Executed all configured import-ldif commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
    if [ "${restartAfterImportLdif}" = "true" ]
    then
      restartOUDInstAfterConfig=false
      restartOUD
    fi
}

# Functions for execCmd commands
# with execCmd_N, any kind of commands can be executed within container
printExecCmdParams() {
  i=0
  echo -n "execCmd Parameters: "	
  for execCmdParam in "${execCmd_1}" "${execCmd_2}" "${execCmd_3}" "${execCmd_4}" "${execCmd_5}" "${execCmd_6}" "${execCmd_7}" "${execCmd_8}" "${execCmd_9}" "${execCmd_10}" "${execCmd_11}" "${execCmd_12}" "${execCmd_13}" "${execCmd_14}" "${execCmd_15}" "${execCmd_16}" "${execCmd_17}" "${execCmd_18}" "${execCmd_19}" "${execCmd_20}" "${execCmd_21}" "${execCmd_22}" "${execCmd_23}" "${execCmd_24}" "${execCmd_25}" "${execCmd_26}" "${execCmd_27}" "${execCmd_28}" "${execCmd_29}" "${execCmd_30}" "${execCmd_31}" "${execCmd_32}" "${execCmd_33}" "${execCmd_34}" "${execCmd_35}" "${execCmd_36}" "${execCmd_37}" "${execCmd_38}" "${execCmd_39}" "${execCmd_40}" "${execCmd_41}" "${execCmd_42}" "${execCmd_43}" "${execCmd_44}" "${execCmd_45}" "${execCmd_46}" "${execCmd_47}" "${execCmd_48}" "${execCmd_49}" "${execCmd_50}" "${execCmd_51}" "${execCmd_52}" "${execCmd_53}" "${execCmd_54}" "${execCmd_55}" "${execCmd_56}" "${execCmd_57}" "${execCmd_58}" "${execCmd_59}" "${execCmd_60}" "${execCmd_61}" "${execCmd_62}" "${execCmd_63}" "${execCmd_64}" "${execCmd_65}" "${execCmd_66}" "${execCmd_67}" "${execCmd_68}" "${execCmd_69}" "${execCmd_70}" "${execCmd_71}" "${execCmd_72}" "${execCmd_73}" "${execCmd_74}" "${execCmd_75}" "${execCmd_76}" "${execCmd_77}" "${execCmd_78}" "${execCmd_79}" "${execCmd_80}" "${execCmd_81}" "${execCmd_82}" "${execCmd_83}" "${execCmd_84}" "${execCmd_85}" "${execCmd_86}" "${execCmd_87}" "${execCmd_88}" "${execCmd_89}" "${execCmd_90}" "${execCmd_91}" "${execCmd_92}" "${execCmd_93}" "${execCmd_94}" "${execCmd_95}" "${execCmd_96}" "${execCmd_97}" "${execCmd_98}" "${execCmd_99}" "${execCmd_100}" "${execCmd_101}" "${execCmd_102}" "${execCmd_103}" "${execCmd_104}" "${execCmd_105}" "${execCmd_106}" "${execCmd_107}" "${execCmd_108}" "${execCmd_109}" "${execCmd_110}" "${execCmd_111}" "${execCmd_112}" "${execCmd_113}" "${execCmd_114}" "${execCmd_115}" "${execCmd_116}" "${execCmd_117}" "${execCmd_118}" "${execCmd_119}" "${execCmd_120}" "${execCmd_121}" "${execCmd_122}" "${execCmd_123}" "${execCmd_124}" "${execCmd_125}" "${execCmd_126}" "${execCmd_127}" "${execCmd_128}" "${execCmd_129}" "${execCmd_130}" "${execCmd_131}" "${execCmd_132}" "${execCmd_133}" "${execCmd_134}" "${execCmd_135}" "${execCmd_136}" "${execCmd_137}" "${execCmd_138}" "${execCmd_139}" "${execCmd_140}" "${execCmd_141}" "${execCmd_142}" "${execCmd_143}" "${execCmd_144}" "${execCmd_145}" "${execCmd_146}" "${execCmd_147}" "${execCmd_148}" "${execCmd_149}" "${execCmd_150}" "${execCmd_151}" "${execCmd_152}" "${execCmd_153}" "${execCmd_154}" "${execCmd_155}" "${execCmd_156}" "${execCmd_157}" "${execCmd_158}" "${execCmd_159}" "${execCmd_160}" "${execCmd_161}" "${execCmd_162}" "${execCmd_163}" "${execCmd_164}" "${execCmd_165}" "${execCmd_166}" "${execCmd_167}" "${execCmd_168}" "${execCmd_169}" "${execCmd_170}" "${execCmd_171}" "${execCmd_172}" "${execCmd_173}" "${execCmd_174}" "${execCmd_175}" "${execCmd_176}" "${execCmd_177}" "${execCmd_178}" "${execCmd_179}" "${execCmd_180}" "${execCmd_181}" "${execCmd_182}" "${execCmd_183}" "${execCmd_184}" "${execCmd_185}" "${execCmd_186}" "${execCmd_187}" "${execCmd_188}" "${execCmd_189}" "${execCmd_190}" "${execCmd_191}" "${execCmd_192}" "${execCmd_193}" "${execCmd_194}" "${execCmd_195}" "${execCmd_196}" "${execCmd_197}" "${execCmd_198}" "${execCmd_199}" "${execCmd_200}" "${execCmd_201}" "${execCmd_202}" "${execCmd_203}" "${execCmd_204}" "${execCmd_205}" "${execCmd_206}" "${execCmd_207}" "${execCmd_208}" "${execCmd_209}" "${execCmd_210}" "${execCmd_211}" "${execCmd_212}" "${execCmd_213}" "${execCmd_214}" "${execCmd_215}" "${execCmd_216}" "${execCmd_217}" "${execCmd_218}" "${execCmd_219}" "${execCmd_220}" "${execCmd_221}" "${execCmd_222}" "${execCmd_223}" "${execCmd_224}" "${execCmd_225}" "${execCmd_226}" "${execCmd_227}" "${execCmd_228}" "${execCmd_229}" "${execCmd_230}" "${execCmd_231}" "${execCmd_232}" "${execCmd_233}" "${execCmd_234}" "${execCmd_235}" "${execCmd_236}" "${execCmd_237}" "${execCmd_238}" "${execCmd_239}" "${execCmd_240}" "${execCmd_241}" "${execCmd_242}" "${execCmd_243}" "${execCmd_244}" "${execCmd_245}" "${execCmd_246}" "${execCmd_247}" "${execCmd_248}" "${execCmd_249}" "${execCmd_250}" "${execCmd_251}" "${execCmd_252}" "${execCmd_253}" "${execCmd_254}" "${execCmd_255}" "${execCmd_256}" "${execCmd_257}" "${execCmd_258}" "${execCmd_259}" "${execCmd_260}" "${execCmd_261}" "${execCmd_262}" "${execCmd_263}" "${execCmd_264}" "${execCmd_265}" "${execCmd_266}" "${execCmd_267}" "${execCmd_268}" "${execCmd_269}" "${execCmd_270}" "${execCmd_271}" "${execCmd_272}" "${execCmd_273}" "${execCmd_274}" "${execCmd_275}" "${execCmd_276}" "${execCmd_277}" "${execCmd_278}" "${execCmd_279}" "${execCmd_280}" "${execCmd_281}" "${execCmd_282}" "${execCmd_283}" "${execCmd_284}" "${execCmd_285}" "${execCmd_286}" "${execCmd_287}" "${execCmd_288}" "${execCmd_289}" "${execCmd_290}" "${execCmd_291}" "${execCmd_292}" "${execCmd_293}" "${execCmd_294}" "${execCmd_295}" "${execCmd_296}" "${execCmd_297}" "${execCmd_298}" "${execCmd_299}" "${execCmd_300}" 
  do
	i=$(expr $i + 1)
	if [ ! -z "${execCmdParam}" ]
	then
	  echo -n "execCmd_${i} [${execCmdParam}] "
    fi
  done
  echo ""
}

execCommands() {
  if [ -z "${execCmd_1}" ]
  then
    return
  fi		
  echo "[$(date)] - Executing execCmd commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
  echo "[$(date)] - Before running execCmd command(s), let's check the status"
  ${SCRIPT_DIR}/checkOUDInstance.sh
  checkOudError=$?
  if [ ${checkOudError} -gt 0 ]; then
    echo "[$(date)] - Error ${checkOudError} running ${SCRIPT_DIR}/checkOUDInstance.sh"
  fi

  # Before invoking execCmd command, let's wait for port to be accessible
  waitForServerPort ${hostname} ${adminConnectorPort}
  
  for execCmdParam in "${execCmd_1}" "${execCmd_2}" "${execCmd_3}" "${execCmd_4}" "${execCmd_5}" "${execCmd_6}" "${execCmd_7}" "${execCmd_8}" "${execCmd_9}" "${execCmd_10}" "${execCmd_11}" "${execCmd_12}" "${execCmd_13}" "${execCmd_14}" "${execCmd_15}" "${execCmd_16}" "${execCmd_17}" "${execCmd_18}" "${execCmd_19}" "${execCmd_20}" "${execCmd_21}" "${execCmd_22}" "${execCmd_23}" "${execCmd_24}" "${execCmd_25}" "${execCmd_26}" "${execCmd_27}" "${execCmd_28}" "${execCmd_29}" "${execCmd_30}" "${execCmd_31}" "${execCmd_32}" "${execCmd_33}" "${execCmd_34}" "${execCmd_35}" "${execCmd_36}" "${execCmd_37}" "${execCmd_38}" "${execCmd_39}" "${execCmd_40}" "${execCmd_41}" "${execCmd_42}" "${execCmd_43}" "${execCmd_44}" "${execCmd_45}" "${execCmd_46}" "${execCmd_47}" "${execCmd_48}" "${execCmd_49}" "${execCmd_50}" "${execCmd_51}" "${execCmd_52}" "${execCmd_53}" "${execCmd_54}" "${execCmd_55}" "${execCmd_56}" "${execCmd_57}" "${execCmd_58}" "${execCmd_59}" "${execCmd_60}" "${execCmd_61}" "${execCmd_62}" "${execCmd_63}" "${execCmd_64}" "${execCmd_65}" "${execCmd_66}" "${execCmd_67}" "${execCmd_68}" "${execCmd_69}" "${execCmd_70}" "${execCmd_71}" "${execCmd_72}" "${execCmd_73}" "${execCmd_74}" "${execCmd_75}" "${execCmd_76}" "${execCmd_77}" "${execCmd_78}" "${execCmd_79}" "${execCmd_80}" "${execCmd_81}" "${execCmd_82}" "${execCmd_83}" "${execCmd_84}" "${execCmd_85}" "${execCmd_86}" "${execCmd_87}" "${execCmd_88}" "${execCmd_89}" "${execCmd_90}" "${execCmd_91}" "${execCmd_92}" "${execCmd_93}" "${execCmd_94}" "${execCmd_95}" "${execCmd_96}" "${execCmd_97}" "${execCmd_98}" "${execCmd_99}" "${execCmd_100}" "${execCmd_101}" "${execCmd_102}" "${execCmd_103}" "${execCmd_104}" "${execCmd_105}" "${execCmd_106}" "${execCmd_107}" "${execCmd_108}" "${execCmd_109}" "${execCmd_110}" "${execCmd_111}" "${execCmd_112}" "${execCmd_113}" "${execCmd_114}" "${execCmd_115}" "${execCmd_116}" "${execCmd_117}" "${execCmd_118}" "${execCmd_119}" "${execCmd_120}" "${execCmd_121}" "${execCmd_122}" "${execCmd_123}" "${execCmd_124}" "${execCmd_125}" "${execCmd_126}" "${execCmd_127}" "${execCmd_128}" "${execCmd_129}" "${execCmd_130}" "${execCmd_131}" "${execCmd_132}" "${execCmd_133}" "${execCmd_134}" "${execCmd_135}" "${execCmd_136}" "${execCmd_137}" "${execCmd_138}" "${execCmd_139}" "${execCmd_140}" "${execCmd_141}" "${execCmd_142}" "${execCmd_143}" "${execCmd_144}" "${execCmd_145}" "${execCmd_146}" "${execCmd_147}" "${execCmd_148}" "${execCmd_149}" "${execCmd_150}" "${execCmd_151}" "${execCmd_152}" "${execCmd_153}" "${execCmd_154}" "${execCmd_155}" "${execCmd_156}" "${execCmd_157}" "${execCmd_158}" "${execCmd_159}" "${execCmd_160}" "${execCmd_161}" "${execCmd_162}" "${execCmd_163}" "${execCmd_164}" "${execCmd_165}" "${execCmd_166}" "${execCmd_167}" "${execCmd_168}" "${execCmd_169}" "${execCmd_170}" "${execCmd_171}" "${execCmd_172}" "${execCmd_173}" "${execCmd_174}" "${execCmd_175}" "${execCmd_176}" "${execCmd_177}" "${execCmd_178}" "${execCmd_179}" "${execCmd_180}" "${execCmd_181}" "${execCmd_182}" "${execCmd_183}" "${execCmd_184}" "${execCmd_185}" "${execCmd_186}" "${execCmd_187}" "${execCmd_188}" "${execCmd_189}" "${execCmd_190}" "${execCmd_191}" "${execCmd_192}" "${execCmd_193}" "${execCmd_194}" "${execCmd_195}" "${execCmd_196}" "${execCmd_197}" "${execCmd_198}" "${execCmd_199}" "${execCmd_200}" "${execCmd_201}" "${execCmd_202}" "${execCmd_203}" "${execCmd_204}" "${execCmd_205}" "${execCmd_206}" "${execCmd_207}" "${execCmd_208}" "${execCmd_209}" "${execCmd_210}" "${execCmd_211}" "${execCmd_212}" "${execCmd_213}" "${execCmd_214}" "${execCmd_215}" "${execCmd_216}" "${execCmd_217}" "${execCmd_218}" "${execCmd_219}" "${execCmd_220}" "${execCmd_221}" "${execCmd_222}" "${execCmd_223}" "${execCmd_224}" "${execCmd_225}" "${execCmd_226}" "${execCmd_227}" "${execCmd_228}" "${execCmd_229}" "${execCmd_230}" "${execCmd_231}" "${execCmd_232}" "${execCmd_233}" "${execCmd_234}" "${execCmd_235}" "${execCmd_236}" "${execCmd_237}" "${execCmd_238}" "${execCmd_239}" "${execCmd_240}" "${execCmd_241}" "${execCmd_242}" "${execCmd_243}" "${execCmd_244}" "${execCmd_245}" "${execCmd_246}" "${execCmd_247}" "${execCmd_248}" "${execCmd_249}" "${execCmd_250}" "${execCmd_251}" "${execCmd_252}" "${execCmd_253}" "${execCmd_254}" "${execCmd_255}" "${execCmd_256}" "${execCmd_257}" "${execCmd_258}" "${execCmd_259}" "${execCmd_260}" "${execCmd_261}" "${execCmd_262}" "${execCmd_263}" "${execCmd_264}" "${execCmd_265}" "${execCmd_266}" "${execCmd_267}" "${execCmd_268}" "${execCmd_269}" "${execCmd_270}" "${execCmd_271}" "${execCmd_272}" "${execCmd_273}" "${execCmd_274}" "${execCmd_275}" "${execCmd_276}" "${execCmd_277}" "${execCmd_278}" "${execCmd_279}" "${execCmd_280}" "${execCmd_281}" "${execCmd_282}" "${execCmd_283}" "${execCmd_284}" "${execCmd_285}" "${execCmd_286}" "${execCmd_287}" "${execCmd_288}" "${execCmd_289}" "${execCmd_290}" "${execCmd_291}" "${execCmd_292}" "${execCmd_293}" "${execCmd_294}" "${execCmd_295}" "${execCmd_296}" "${execCmd_297}" "${execCmd_298}" "${execCmd_299}" "${execCmd_300}" 
  do
	if [ ! -z "${execCmdParam}" ]
	then	 
      updatedParam=$(echo ${execCmdParam} \
	  		 | sed \
	  		 -e "s|\${hostname}|${hostname}|g" \
	  		 -e "s|\${ldapPort}|${ldapPort}|g" \
	  		 -e "s|\${ldapsPort}|${ldapsPort}|g" \
	  		 -e "s|\${adminConnectorPort}|${adminConnectorPort}|g" \
	  		 -e "s|\${replicationPort}|${replicationPort}|g" \
	  		 -e "s|\${sourceHost}|${sourceHost}|g" \
	  		 -e "s|\${initializeFromHost}|${initializeFromHost}|g" \
	  		 -e "s|\${sourceAdminConnectorPort}|${sourceAdminConnectorPort}|g" \
	  		 -e "s|\${sourceReplicationPort}|${sourceReplicationPort}|g" \
	  		 -e "s|\${baseDN}|${baseDN}|g" \
			 -e "s|\${rootUserDN}|${rootUserDN}|g" \
			 -e "s|\${adminUID}|${adminUID}|g" \
			 -e "s|\${rootPwdFile}|${rootPwdFile}|g" \
			 -e "s|\${bindPasswordFile}|${rootPwdFile}|g" \
			 -e "s|\${adminPwdFile}|${adminPwdFile}|g" \
			 -e "s|\${bindPwdFile1}|${bindPwdFile1}|g" \
			 -e "s|\${bindPwdFile2}|${bindPwdFile2}|g" \
	  			  )
  	  echo "[$(date)] - Executing execCmd with parameters ${execCmdParam} -> ${updatedParam}"
	  execCmdParam=${updatedParam}
      echo eval ${execCmdParam} >> ${execCmdCmdLogs}
      eval ${execCmdParam} > ${execCmdCmdLogs}.tmp 2>&1
      execStatus=$?
	  cat ${execCmdCmdLogs}.tmp | tee -a ${execCmdCmdLogs}
      echo "[$(date)] - execStatus [${execStatus}]"
      if [ ${execStatus} -gt 0 -a "${ignoreErrorExecCmd}" = "false" ]
      then
        echo "[$(date)] - execStatus [${execStatus}] - Considering ignoreErrorExecCmd=false, exiting ..."
        exit 1
      fi
	fi
  done
  echo "[$(date)] - Executed all configured execCmd commands" 2>&1 | tee -a ${oudInstanceConfigStatus}
}

