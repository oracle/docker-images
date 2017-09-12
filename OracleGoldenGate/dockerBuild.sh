#!/bin/bash
# Copyright (c) 2017 Oracle and/or its affiliates.  All rights reserved.
#
# The Universal Permissive License (UPL), Version 1.0
#
# Subject to the condition set forth below, permission is hereby granted to any person obtaining a copy of this
# software, associated documentation and/or data (collectively the "Software"), free of charge and under any and
# all copyright rights in the Software, and any and all patent rights owned or freely licensable by each licensor
# hereunder covering either (i) the unmodified Software as contributed to or provided by such licensor, or
# (ii) the Larger Works (as defined below), to deal in both
#
# (a) the Software, and
# (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if one is included with the Software
# (each a “Larger Work” to which the Software is contributed by such licensors),
#
# without restriction, including without limitation the rights to copy, create derivative works of, display,
# perform, and distribute the Software and make, use, sell, offer for sale, import, export, have made, and have
# sold the Software and the Larger Work(s), and to sublicense the foregoing rights on either these or other terms.
#
# This license is subject to the following condition:
# The above copyright notice and either this complete permission notice or at a minimum a reference to the UPL must
# be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

#
# Since:        July, 2017
# Author:       Stephen Balousek <stephen.balousek@oracle.com>
# Description:  Create a Docker image from an Oracle GoldenGate ZIP distribution.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

if [[ "${1:--h}" == "-h" ]]; then
    echo "Oracle GoldenGate distribution ZIP file not specified."
    echo ""
    echo "Usage: $(basename $0) [-h | <ogg-zip-file-name>] [<docker-build-options> ...]"
    echo "Where:"
    echo "  ogg-zip-file-name       Name of OGG ZIP file"
    echo "  docker-build-options    Command line options for Docker build"
    echo ""
    echo "Example:"
    echo "  $(basename $0) ~/Downloads/fbo_ggs_Linux_x64_shiphome.zip --no-cache"
    exit 1
fi

OGG_DISTFILE="$(readlink -f $1)"
if [[ ! -f "${OGG_DISTFILE}" ]]; then
    echo "Oracle GoldenGate distribution ZIP file '$1' not found."
    exit 1
fi
shift
pushd "$(dirname $(command -v $0))" &>/dev/null

function cleanupAndExit {
    [[ "${OGG_DISTFILE}" != $(readlink -f "${OGG_TARFILE}") ]] && \
        rm -f "${OGG_TARFILE}" ggstar
    exit ${1-1}
}
trap cleanupAndExit SIGTERM SIGINT

if [[ "${OGG_DISTFILE/.zip/}" != "${OGG_DISTFILE}" ]]; then
    targetJAR="$(basename ${OGG_DISTFILE} .zip)/Disk1/stage/Components/oracle.oggcore.*ora12c/*/1/DataFiles/filegroup1.jar"
    OGG_JARFILE="$(unzip -qp ${OGG_DISTFILE} ${targetJAR} 2>/dev/null > $(basename ${targetJAR}) && echo $(basename ${targetJAR}) || rm $(basename ${targetJAR}))"
    [[ "${OGG_JARFILE}" != "" ]] && {
        OGG_TARFILE="$(basename ${OGG_DISTFILE} .zip).tar"
    } || {
        OGG_TARFILE="$(unzip -o ${OGG_DISTFILE} *.tar | awk '/.*[.]tar/ { print $NF; exit 0 }')"
    }
fi
if [[ "${OGG_DISTFILE/.tgz/}" != "${OGG_DISTFILE}" ]]; then
    gzip="$(command -v pigz 2>/dev/null)" || gzip=gzip
    OGG_TARFILE="$(basename ${OGG_DISTFILE} .tgz).tar"
    $gzip -d < "${OGG_DISTFILE}" > "${OGG_TARFILE}"
fi
if [[ "${OGG_DISTFILE/.tar/}" != "${OGG_DISTFILE}" ]]; then
    OGG_TARFILE="$(basename ${OGG_DISTFILE})"
    if [[ "${OGG_DISTFILE}" != $(readlink -f "${OGG_TARFILE}") ]]; then
        cp -a "${OGG_DISTFILE}" "${OGG_TARFILE}"
    fi
fi

function getVersion {
    local      Version=$(strings $1 2>/dev/null | awk '/^Version[ ]1/ {print $2; exit 0;}')
    [[ ! -z  ${Version} ]] && \
        echo ${Version}
}

mkdir   ggstar
[[ ! -z "${OGG_JARFILE}" ]] && {
    unzip -q  ${OGG_JARFILE} -d ggstar
    rm    -f  ${OGG_JARFILE}
} || {
    [[ !  -z "${OGG_TARFILE}" ]] && tar Cxf ggstar ${OGG_TARFILE}
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
find    ggstar -type f \( -name '*.so*' -o -not -name '*.*' \) -exec chmod +x {} \;
tar Ccf ggstar ${OGG_TARFILE} --owner=54321 --group=54321 .
rm -fr  ggstar

[[ ! -z "${BASE_IMAGE}" ]] && BASE_IMAGE_ARG="--build-arg BASE_IMAGE=${BASE_IMAGE}"
[[ ! -z "${http_proxy}" ]] && HTTP_PROXY_ARG="--build-arg http_proxy=${http_proxy}"

docker build ${BASE_IMAGE_ARG} \
             ${HTTP_PROXY_ARG} \
             --build-arg OGG_VERSION=${OGG_VERSION} \
             --build-arg OGG_EDITION=${OGG_EDITION} \
             --build-arg OGG_TARFILE=${OGG_TARFILE} \
             --tag oracle/goldengate-${OGG_EDITION}:${OGG_VERSION} "$@" .
cleanupAndExit $?
