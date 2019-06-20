#!/bin/bash
# Copyright (c) 2017 Oracle and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

#
# Since:        July, 2017
# Author:       Stephen Balousek <stephen.balousek@oracle.com>
# Description:  Create a Docker image from an Oracle GoldenGate ZIP distribution.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

##
## Locate a command on the local system
##
function getCommand {
    local primary=$1; shift
    local alternate=$*
    for check in ${alternate} ${primary}; do
        command=$(command -v ${check} 2>/dev/null) && break
    done
    [[ -z "${command}" ]] && {
        [[ ! -z "${alternate}" ]] && echo "Error: Cannot locate command ${primary} or ${alternate}" \
                                  || echo "Error: Cannot locate command ${primary}"
        exit 1
    }
    cmdname=$(echo ${primary} | tr a-z A-Z)
    eval "${cmdname}=\"${command}\""
}

##
## Required commands
##
getCommand tr
getCommand awk      gawk
getCommand basename
getCommand dirname
getCommand docker
getCommand find
getCommand readlink greadlink
getCommand strings
getCommand tar      gtar

##
## Display Usage
##
if [[ "${1:--h}" == "-h" ]]; then
    echo "Oracle GoldenGate distribution ZIP file not specified."
    echo ""
    echo "Usage: $(${BASENAME} $0) [-h | <ogg-zip-file-name>] [<docker-build-options> ...]"
    echo "Where:"
    echo "  ogg-zip-file-name       Name of OGG ZIP file"
    echo "  docker-build-options    Command line options for Docker build"
    echo ""
    echo "Example:"
    echo "  ./$(${BASENAME} $0) ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip --no-cache"
    exit 1
fi

function getTargetFilename {
    local Target="$1"
    if [[ "$(uname)" == "Linux" ]]; then
        ${READLINK} -f "${Target}"
    else
        while ( true ); do
            cd $(${DIRNAME} "${Target}")
            Target=$(${BASENAME} "${Target}")
            [[ ! -L "${Target}" ]] && break
            Target=$(${READLINK} "${Target}")
        done
        echo $(pwd -P)/${Target}
    fi
}

OGG_DISTFILE="$(getTargetFilename $1)"
if [[ ! -f "${OGG_DISTFILE}" ]]; then
    echo "Oracle GoldenGate distribution ZIP file '$1' not found."
    exit 1
fi
shift
pushd "$(${DIRNAME} $(command -v $0))" &>/dev/null

function cleanupAndExit {
    [[ "${OGG_DISTFILE}" != $(getTargetFilename "${OGG_TARFILE}") ]] && \
        rm -f "${OGG_TARFILE}" ggstar
    exit ${1-1}
}
trap cleanupAndExit SIGTERM SIGINT

if [[ "${OGG_DISTFILE/.zip/}" != "${OGG_DISTFILE}" ]]; then
    getCommand unzip
    targetJAR="*/Disk1/stage/Components/oracle.oggcore.*ora12c/*/1/DataFiles/filegroup1.jar"
    OGG_JARFILE="$(${UNZIP} -qp ${OGG_DISTFILE} ${targetJAR} 2>/dev/null > $(${BASENAME} ${targetJAR}) && echo $(${BASENAME} ${targetJAR}) || rm $(${BASENAME} ${targetJAR}))"
    [[ "${OGG_JARFILE}" != "" ]] && {
        OGG_TARFILE="$(${BASENAME} ${OGG_DISTFILE} .zip).tar"
    } || {
        OGG_TARFILE="$(${UNZIP} -o ${OGG_DISTFILE} *.tar* 2>/dev/null | ${AWK} '/.*[.]tar/ { print $NF; exit 0 }')"
    }
fi
if [[ "${OGG_DISTFILE/.tgz/}" != "${OGG_DISTFILE}" ]]; then
    getCommand gzip pigz
    OGG_TARFILE="$(${BASENAME} ${OGG_DISTFILE} .tgz).tar"
    ${GZIP} -d < "${OGG_DISTFILE}" > "${OGG_TARFILE}"
fi
if [[ "${OGG_DISTFILE/.tar/}" != "${OGG_DISTFILE}" ]]; then
    OGG_TARFILE="$(${BASENAME} ${OGG_DISTFILE})"
    if [[ "${OGG_DISTFILE}" != $(getTargetFilename "${OGG_TARFILE}") ]]; then
        cp -a "${OGG_DISTFILE}" "${OGG_TARFILE}"
    fi
fi

function getVersion {
    local      Version=$(${STRINGS} $1 2>/dev/null | ${AWK} '/^Version[ ]1/ {print $2; exit 0;}')
    [[ ! -z  ${Version} ]] && \
        echo ${Version}
}

mkdir   ggstar
[[ ! -z "${OGG_JARFILE}" ]] && {
    getCommand unzip
    ${UNZIP} -q  ${OGG_JARFILE} -d ggstar
    rm       -f  ${OGG_JARFILE}
} || {
    [[ !  -z "${OGG_TARFILE}" ]] && ${TAR} Cxf ggstar ${OGG_TARFILE}
}
OGG_VERSION=$(getVersion ggstar/keygen) && {
    OGG_EDITION="standard"
} || {
    OGG_VERSION=$(getVersion ggstar/bin/keygen) && {
        OGG_EDITION="microservices"
    } || {
        rm -fr ggstar
        echo "Distribution file '${OGG_DISTFILE}' does not appear to be a GoldenGate ZIP distribution"
        cleanupAndExit 1
    }
}
${FIND}    ggstar -type f \( -name '*.so*' -o -not -name '*.*' \) -exec chmod +x {} \;
${TAR} Ccf ggstar ${OGG_TARFILE} --owner=54321 --group=54321 .
rm -fr     ggstar

[[ ! -z "${BASE_IMAGE}"  ]] && BASE_IMAGE_ARG="--build-arg BASE_IMAGE=${BASE_IMAGE}"
[[ ! -z "${http_proxy}"  ]] && HTTP_PROXY_ARG="--build-arg http_proxy=${http_proxy}"
[[ ! -z "${https_proxy}" ]] && HTTPS_PROXY_ARG="--build-arg https_proxy=${https_proxy}"

"${DOCKER}" build ${BASE_IMAGE_ARG} \
                ${HTTP_PROXY_ARG} ${HTTPS_PROXY_ARG} \
                --build-arg OGG_VERSION=${OGG_VERSION} \
                --build-arg OGG_EDITION=${OGG_EDITION} \
                --build-arg OGG_TARFILE=${OGG_TARFILE} \
                --tag oracle/goldengate-${OGG_EDITION}:${OGG_VERSION} "$@" .
cleanupAndExit $?
