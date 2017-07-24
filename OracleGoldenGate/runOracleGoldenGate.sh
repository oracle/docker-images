#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# Since:        July, 2017
# Author:       Stephen Balousek <stephen.balousek@oracle.com>
# Description:  Initialize and run Oracle GoldenGate in a Docker container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

runAsUser="runuser -u oracle --"
OGGProcesses="(adminclient|adminsrvr|distsrvr|extract|ggsci|pmsrvr|recvsrvr|replicat|server|ServiceManager)"

##
## Set some reasonable defaults
##
[[ -z "${OGG_SCHEMA}" ]] && export OGG_SCHEMA="oggadmin"
[[ -z "${OGG_ADMIN}"  ]] && export OGG_ADMIN="oggadmin"
[[ -z "${PORT_BASE}"  ]] && {
    case "${OGG_EDITION}" in
        "standard")
            export PORT_BASE=7809
            ;;
        "microservices")
            export PORT_BASE=9100
            ;;
    esac
}

##
## Set up administrator password for Microservices Architecture
##
if [[ "${OGG_EDITION}" == "microservices" ]]; then
    if [[ -z "${OGG_ADMIN_PWD}" ]]; then
         export OGG_ADMIN_PWD="$(openssl rand -base64 9)"
         echo "----------------------------------------------------------------------------------"
         echo "--  Password for administrative user '${OGG_ADMIN}' is '${OGG_ADMIN_PWD}'"
         echo "----------------------------------------------------------------------------------"
     fi
fi

##
## Monitor a report file
##
function tailReport {
    local rptFile="$1"
    while [[ ! -f  "${rptFile}" ]]; do
        sleep 1
    done
    tail --lines=+1 -F ${rptFile}
}

##
## Mark applications and shared libraries executable
##
function setExecutable {
    find ${OGG_HOME} -type f \( -name '*.so*' -o -not -name '*.*' \) -exec chmod +x {} \;
}

##
##  Check if any OGG components are running
##
function isOGGRunning {
    pgrep -f ${OGGProcesses} &>/dev/null
}

##
## Oracle GoldenGate Standard Edition functions
##
function createSubdirs {
    echo "Create Subdirs" | ${runAsUser} ${OGG_HOME}/ggsci
}

function createDatastore {
    [[ "${OGG_VERSION}" < "12.3.0.1.0" ]] && \
        echo "Create Datastore MMAP" | ${runAsUser} ${OGG_HOME}/ggsci
}

function createManagerParameters {
    [[ ! -f ${OGG_HOME}/dirprm/MGR.prm ]] && \
        ${runAsUser} bash -c "echo Port ${Port_Manager} > ${OGG_HOME}/dirprm/MGR.prm"
}

function createGlobals {
    [[ ! -f ${OGG_HOME}/GLOBALS ]] && \
        ${runAsUser} bash -c "echo GGSCHEMA ${OGG_SCHEMA} > ${OGG_HOME}/GLOBALS"
}

##
## Oracle GoldenGate Microservices Architecture functions
##
CommonOU="OU=GoldenGate,OU=Enterprise Replication,OU=Server Technology,O=Oracle Corp,L=Redwood Shores,ST=CA,C=US"
orapki="${runAsUser} orapki -nologo"

function initSSL {
    local    deploymentName="$1"
    initCA ${deploymentName}
    initDN ${deploymentName} $(hostname)
}

function initCA {
    local    deploymentName="$1"
    createWallet "${deploymentName}" || return 0
    ${runAsUser} bash -c "date +%s  > ${OGG_DEPLOY_BASE}/ssl/${deploymentName}.serial"
    ${orapki} crl      create -wallet ${OGG_DEPLOY_BASE}/ssl/${deploymentName} -pwd "${OGG_ADMIN_PWD}" -crl ${OGG_DEPLOY_BASE}/ssl/${deploymentName}.crl
}

function initDN {
    local    deploymentName="$1"
    local          hostName="$2"
    local    deploymentCert="${OGG_DEPLOY_BASE}/ssl/${hostName}/${deploymentName}.crt"
    local       hostRequest="/tmp/${hostName}.csr"
    local          hostCert="/tmp/${hostName}.crt"

    createWallet ${hostName} || return 0

    ${orapki} wallet export  -wallet ${OGG_DEPLOY_BASE}/ssl/${deploymentName} -pwd "${OGG_ADMIN_PWD}" -dn "CN=${deploymentName},${CommonOU}" -cert    ${deploymentCert}
    ${orapki} wallet add     -wallet ${OGG_DEPLOY_BASE}/ssl/${hostName}       -pwd "${OGG_ADMIN_PWD}"                          -trusted_cert -cert    ${deploymentCert}
    rm -f                                                                                                                                         ${deploymentCert}

    ${orapki} wallet export  -wallet ${OGG_DEPLOY_BASE}/ssl/${hostName}       -pwd "${OGG_ADMIN_PWD}" -dn "CN=${hostName},${CommonOU}"       -request ${hostRequest}
    ${orapki} cert   create  -wallet ${OGG_DEPLOY_BASE}/ssl/${deploymentName} -pwd "${OGG_ADMIN_PWD}" -validity 3650                         -request ${hostRequest} \
                        -serial_file ${OGG_DEPLOY_BASE}/ssl/${deploymentName}.serial                                                         -cert    ${hostCert}
    rm -f                                                                                                                                             ${hostRequest}
    ${orapki} wallet replace -wallet ${OGG_DEPLOY_BASE}/ssl/${hostName}       -pwd "${OGG_ADMIN_PWD}"                          -user_cert    -cert    ${hostCert}
    rm -f                                                                                                                                             ${hostCert}
}

function createWallet {
    local        walletName="$1"
    mkdir -p ${OGG_DEPLOY_BASE}/ssl/${walletName} 2>/dev/null || return 1
    ${orapki} wallet create  -wallet ${OGG_DEPLOY_BASE}/ssl/${walletName}     -pwd "${OGG_ADMIN_PWD}" -auto_login
    ${orapki} wallet add     -wallet ${OGG_DEPLOY_BASE}/ssl/${walletName}     -pwd "${OGG_ADMIN_PWD}" -dn "CN=${walletName},${CommonOU}" -keysize 2048 -self_signed -validity 7300
}

function initShell {
    cat<<EOF | ${runAsUser} bash -c 'cat > ${HOME}/.bashrc'
export OGG_ETC_HOME="${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}/etc"
export OGG_VAR_HOME="${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}/var"
EOF
}

function createDeployment {
    if [[ "${OGG_SECURE}" == "true" ]]; then
        secureOption=""
        if [[ ! -z "${OGG_SERVER_WALLET}" ]]; then
            secureOption="${secureOption} --serverWrl=${OGG_SERVER_WALLET}"
        fi
        if [[ ! -z "${OGG_CLIENT_WALLET}" ]]; then
            secureOption="${secureOption} --clientWrl=${OGG_CLIENT_WALLET}"
        fi
        if [[ ! -z "${OGG_CLIENT_ROLE}" ]]; then
            secureOption="${secureOption} --clientRole=${OGG_CLIENT_ROLE}"
        fi
        if [[ ! -z "${OGG_CLIENT_INFO}" ]]; then
            secureOption="${secureOption} --clientInfo=${OGG_CLIENT_INFO}"
        fi
        if [[ "${secureOption}" == "" ]]; then
            initSSL ${OGG_DEPLOYMENT}
            secureOption="--serverWrl=${OGG_DEPLOY_BASE}/ssl/${OGG_DEPLOYMENT}"
        fi
    else
        secureOption="--nonSecure"
    fi

    local OGG_JARFILE=$(ls -1 ${OGG_HOME}/lib/utl/install/oggsca*-jar-with-dependencies.jar)
    mkdir -p "${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}"
    chown -r oracle:oinstall "${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}"

    echo "${OGG_ADMIN_PWD}" | \
    ${runAsUser} java -classpath  ${OGG_JARFILE} ogg/OGGDeployment \
         --action=Create --silent \
         --oggHome=${OGG_HOME} \
         --oggDeployHome=${OGG_DEPLOY_BASE}/ServiceManager \
         --deploymentName=ServiceManager --authUser=${OGG_ADMIN} \
         --serviceListeningPort=${Port_ServiceManager} --createNewServiceManager=Yes \
        ${secureOption}

    echo "${OGG_ADMIN_PWD}" | \
    ${runAsUser} java -classpath ${OGG_JARFILE} ogg/OGGDeployment \
         --action=Create --silent \
         --oggHome=${OGG_HOME} \
         --oggDeployHome=${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT} \
         --deploymentName=${OGG_DEPLOYMENT} --authUser=${OGG_ADMIN} \
         --serviceListeningPort=${Port_ServiceManager} \
         --portAdminSrvr=${Port_AdminServer} \
         --portDistSrvr=${Port_DistributionServer} \
         --portRcvrSrvr=${Port_ReceiverServer} \
         --portPmSrvr=${Port_MetricsServer} --enablePmSrvr=Yes \
         --portPmSrvrUdp=${Port_MetricsServerUDP} \
         --ggSchema=${OGG_SCHEMA} \
        ${secureOption}
}

function startReverseProxy {
    [[ -z "${OGG_HTTPS}"           ]] && export OGG_HTTPS="${OGG_SECURE}"
    [[    "${OGG_HTTPS}" == "true" ]] && SCHEME="https" || SCHEME="http"
    ${OGG_HOME}/lib/utl/reverseproxy/ReverseProxySettings -o /etc/nginx/conf.d/ogg.conf -t nginx "$SCHEME://127.0.0.1:${Port_ServiceManager}"
    scl enable rh-nginx18 -- nginx
}

##
## Oracle GoldenGate Standard Edition
##
Port_Manager=$(expr ${PORT_BASE})

function init_standard {
    setExecutable
    createSubdirs
    createDatastore
    createManagerParameters
    createGlobals
}

function exec_standard {
    local rptFile="${OGG_HOME}/dirrpt/MGR.rpt"
    local prmFile="${OGG_HOME}/dirprm/MGR.prm"
    ${runAsUser}   ${OGG_HOME}/mgr PARAMFILE ${prmFile} REPORTFILE ${rptFile} &>/dev/null &
    tailReport     ${rptFile}
}

function term_standard {
    echo -e "\nTerminating..."
    echo "Stop ER * !" | ${runAsUser} ${OGG_HOME}/ggsci
    echo "Stop MGR  !" | ${runAsUser} ${OGG_HOME}/ggsci
    exit 1
}

##
## Oracle GoldenGate Microservices Architecture
##
Port_ServiceManager=$(expr ${PORT_BASE})
Port_AdminServer=$(expr ${PORT_BASE} + 1)
Port_DistributionServer=$(expr ${PORT_BASE} + 2)
Port_ReceiverServer=$(expr ${PORT_BASE} + 3)
Port_MetricsServer=$(expr ${PORT_BASE} + 4)
Port_MetricsServerUDP=$(expr ${PORT_BASE} + 4)

function init_microservices {
    [[ -z "${OGG_DEPLOYMENT}"       ]] && export OGG_DEPLOYMENT="Local"
    [[    "${OGG_SECURE}" == "1"    ]] && export OGG_SECURE="true"
    [[    "${OGG_SECURE}" != "true" ]] && export OGG_SECURE="false"
    setExecutable
    initShell
    createDeployment
}

function exec_microservices {
    export OGG_ETC_HOME="${OGG_DEPLOY_BASE}/ServiceManager/etc"
    export OGG_VAR_HOME="${OGG_DEPLOY_BASE}/ServiceManager/var"
    ${runAsUser} ${OGG_HOME}/bin/ServiceManager '{ "config": { "inventoryLocation": "'${OGG_ETC_HOME}/conf'", "network": { "serviceListeningPort": '${Port_ServiceManager}' }, "authorizationEnabled": true, "security": '${OGG_SECURE}' } }' &>/dev/null &
    startReverseProxy
    tailReport "${OGG_VAR_HOME}/log/ServiceManager.log"
}

function term_microservices {
    echo ""
    pkill -SIGTERM ServiceManager                         && sleep 1
    pkill -SIGTERM '(adminsrvr|distsrvr|pmsrvr|recvsrvr)' && sleep 1
    pkill -SIGTERM '(extract|replicat)'
    local timeout=8
    local rc=0
    while (true); do
        isOGGRunning || return 0
        sleep 1
        timeout=$(expr ${timeout} - 1)
        if [ ${timeout} -eq 0 ]; then
            rc=1
            break
        fi
    done
    pkill -SIGKILL ${OGGProcesses}
    exit ${rc}
}

##
## Main logic
##
trap term_${OGG_EDITION} SIGTERM SIGINT
     init_${OGG_EDITION} && \
     exec_${OGG_EDITION}
