#!/bin/bash
# Copyright (c) 2017-2018 Oracle and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

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
[[ -z "${HOSTNAME}"   ]] && export HOSTNAME="${$(hostname 2>/dev/null):-localhost}"
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
## Generate a random password with:
##  - at least one uppercase character
##  - at least one lowercase character
##  - at least one digit character
##
function generatePassword {
    local password="$(openssl rand -base64 9)-$(openssl rand -base64 3)"
    if [[ "${password}" != "${password/[A-Z]/_}" && \
          "${password}" != "${password/[a-z]/_}" && \
          "${password}" != "${password/[0-9]/_}" ]]; then
        export OGG_ADMIN_PWD="${password}"
        return
    fi
    generatePassword
}

##
## Set up administrator password for Microservices Architecture
##
if [[ "${OGG_EDITION}" == "microservices" ]]; then
    if [[ -z "${OGG_ADMIN_PWD}" ]]; then
         generatePassword
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
## Hook for launching another entrypoint in the container
## If defined, the command identified by ${BASE_COMMAND} will be run in the background.
##
function runBaseCommand {
    [[ ! -z "${BASE_COMMAND}" ]] && \
        ${BASE_COMMAND} &
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
    if [[ ! -f ${OGG_HOME}/GLOBALS ]]; then
        ${runAsUser} bash -c "echo GGSCHEMA ${OGG_SCHEMA} > ${OGG_HOME}/GLOBALS"
    else
        return 0
    fi
}

##
## Oracle GoldenGate Microservices Architecture functions
##
function initSSL {
    if [[ ! -d "${OGG_DEPLOY_BASE}/ssl" ]]; then
        local deploymentName="$1"
        local       CommonOU="OU=GoldenGate,OU=Enterprise Replication,OU=Server Technology,O=Oracle Corp,L=Redwood Shores,ST=CA,C=US"
        local         orapki="${runAsUser} orapki -nologo"
        local OGG_WALLET_PWD="${OGG_ADMIN_PWD}-A1"
        local      nginxCert="/etc/nginx/ogg.pem"

        mkdir -p                         ${OGG_DEPLOY_BASE}/ssl
        chown     oracle:oinstall        ${OGG_DEPLOY_BASE}/ssl
        ${runAsUser} mkdir -p            ${OGG_DEPLOY_BASE}/ssl/${HOSTNAME} 2>/dev/null || return 1
        ${orapki} wallet create  -wallet ${OGG_DEPLOY_BASE}/ssl/${HOSTNAME} -pwd "${OGG_WALLET_PWD}" -auto_login
        ${orapki} wallet add     -wallet ${OGG_DEPLOY_BASE}/ssl/${HOSTNAME} -pwd "${OGG_WALLET_PWD}" -dn "CN=${deploymentName},${CommonOU}" -keysize 2048 -self_signed -validity 7300

        chmod 644               ${nginxCert}
        ${orapki} wallet add     -wallet ${OGG_DEPLOY_BASE}/ssl/${HOSTNAME} -pwd "${OGG_WALLET_PWD}" -trusted_cert -cert ${nginxCert}
        chmod 600               ${nginxCert}
    fi
}

function initShell {
    if (! grep OGG_ETC_HOME "/home/oracle/.bashrc" 2>/dev/null ); then
        cat<<EOF | ${runAsUser} bash -c 'cat >> /home/oracle/.bashrc'
export OGG_ETC_HOME="${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}/etc"
export OGG_VAR_HOME="${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}/var"
EOF
    fi
}

function createDeployment {
    if [[ "${OGG_SECURE}" == "true" && -z "${OGG_SERVER_WALLET}" ]]; then
        OGG_SERVER_WALLET="${OGG_DEPLOY_BASE}/ssl/${HOSTNAME}"
    fi
    if [[ -z "${OGG_CLIENT_WALLET}" ]]; then
        OGG_CLIENT_WALLET="${OGG_DEPLOY_BASE}/ssl/${HOSTNAME}"
    fi

    secureOption=""
    if [[ ! -z "${OGG_SERVER_WALLET}" ]]; then
        secureOption="${secureOption} --serverWrl=${OGG_SERVER_WALLET}"
    else
        secureOption="${secureOption} --nonSecure"
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

    initSSL ${OGG_DEPLOYMENT}

    local OGG_JARFILE=$(ls -1 ${OGG_HOME}/lib/utl/install/oggsca*.jar)
    chown -R oracle:oinstall "${OGG_DEPLOY_BASE}"

    if [[ ! -e "${OGG_DEPLOY_BASE}/ServiceManager/etc/conf/deploymentRegistry.dat" ]]; then
        echo "${OGG_ADMIN_PWD}" | \
        ${runAsUser} java -classpath  ${OGG_JARFILE} ogg/OGGDeployment \
             --action=Create --silent \
             --oggHome=${OGG_HOME} \
             --oggDeployHome=${OGG_DEPLOY_BASE}/ServiceManager \
             --deploymentName=ServiceManager --authUser=${OGG_ADMIN} \
             --serviceListeningPort=${Port_ServiceManager} --createNewServiceManager=Yes \
            ${secureOption}
    fi

    if [[ ! -e "${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT}/etc/conf/deploymentConfiguration.dat" ]]; then
        echo "${OGG_ADMIN_PWD}" | \
        ${runAsUser} java -classpath ${OGG_JARFILE} ogg/OGGDeployment \
             --action=Create --silent \
             --oggHome=${OGG_HOME} \
             --oggDeployHome=${OGG_DEPLOY_BASE}/${OGG_DEPLOYMENT} \
             --deploymentName=${OGG_DEPLOYMENT} --authUser=${OGG_ADMIN} \
             --serviceListeningPort=${Port_ServiceManager} --createNewServiceManager=No \
             --portAdminSrvr=${Port_AdminServer} \
             --portDistSrvr=${Port_DistributionServer} \
             --portRcvrSrvr=${Port_ReceiverServer} \
             --portPmSrvr=${Port_MetricsServer} --enablePmSrvr=Yes \
             --portPmSrvrUdp=${Port_MetricsServerUDP} \
             --ggSchema=${OGG_SCHEMA} \
            ${secureOption}
    else
        return 0
    fi
}

function startReverseProxy {
    if [[ ! -f "/etc/nginx/conf.d/ogg.conf" ]]; then
        [[ -z "${OGG_HTTPS}"           ]] && export OGG_HTTPS="${OGG_SECURE}"
        [[    "${OGG_HTTPS}" == "true" ]] && SCHEME="https" || SCHEME="http"
        if [[ "$(${OGG_HOME}/lib/utl/reverseproxy/ReverseProxySettings -v)" == "1.0" ]]; then
            ${OGG_HOME}/lib/utl/reverseproxy/ReverseProxySettings -o /etc/nginx/conf.d/ogg.conf -t nginx                 "${SCHEME}://127.0.0.1:${Port_ServiceManager}"
        else
            echo ${OGG_ADMIN_PWD} | \
            ${OGG_HOME}/lib/utl/reverseproxy/ReverseProxySettings -o /etc/nginx/conf.d/ogg.conf -t nginx -u ${OGG_ADMIN} "${SCHEME}://127.0.0.1:${Port_ServiceManager}"
        fi
    fi
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
    [[   -z "${OGG_DEPLOYMENT}"       ]] && export OGG_DEPLOYMENT="Local"
    [[ ! -z "${OGG_SERVER_WALLET}"    ]] && export OGG_SECURE="true"
    [[      "${OGG_SECURE}" != "true" ]] && export OGG_SECURE="false"
    setExecutable
    initShell
    createDeployment
}

function exec_microservices {
    export OGG_ETC_HOME="${OGG_DEPLOY_BASE}/ServiceManager/etc"
    export OGG_VAR_HOME="${OGG_DEPLOY_BASE}/ServiceManager/var"
    isOGGRunning || ${runAsUser} ${OGG_HOME}/bin/ServiceManager &
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
runBaseCommand
trap term_${OGG_EDITION} SIGTERM SIGINT
     init_${OGG_EDITION} && \
     exec_${OGG_EDITION}
