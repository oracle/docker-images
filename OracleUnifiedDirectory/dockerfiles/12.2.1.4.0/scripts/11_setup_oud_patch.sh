#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 11_setup_oud_patch.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.09.27
# Revision...: 
# Purpose....: Script to patch Oracle Unified Directory binaries
# Notes......: - Script would like to be executed as oracle :-)
#              - If the required software is not in /opt/stage, an attempt is
#                made to download the software package with curl from 
#                ${SOFTWARE_REPO} In this case, the environment variable must 
#                point to a corresponding URL.
# Reference..: This script is a copy from the Git repository 
#              https://github.com/oehrlis/oradba_init 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
# - Environment Variables ---------------------------------------------------
# source genric environment variables and functions
source "$(dirname ${BASH_SOURCE[0]})/00_setup_oradba_init.sh"

# define the software packages
export OUD_PATCH_PKG=${OUD_PATCH_PKG:-""}
export FMW_PATCH_PKG=${FMW_PATCH_PKG:-""}
export OUD_OPATCH_PKG=${OUD_OPATCH_PKG:-""}
export OUI_PATCH_PKG=${OUI_PATCH_PKG:-""}
export OPATCH_NO_FUSER=true

# define oradba specific variables
export ORADBA_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export ORADBA_BASE="$(dirname ${ORADBA_BIN})"

# define Oracle specific variables
export ORACLE_HOME_NAME=${ORACLE_HOME_NAME:-"oud11.1.2.3.0"}
export ORACLE_HOME="${ORACLE_HOME:-${ORACLE_BASE}/product/${ORACLE_HOME_NAME}}"

# define generic variables for software, download etc
export JAVA_HOME=${JAVA_HOME:-$(dirname $(dirname $(find ${ORACLE_BASE} /usr/java -name javac 2>/dev/null|sort -r|head -1) 2>/dev/null) 2>/dev/null)}
export OPT_DIR=${OPT_DIR:-"/opt"}
export SOFTWARE=${SOFTWARE:-"${OPT_DIR}/stage"} # local software stage folder
export SOFTWARE_REPO=${SOFTWARE_REPO:-""}       # URL to software for curl fallback
export DOWNLOAD=${DOWNLOAD:-"/tmp/download"}    # temporary download location
export CLEANUP=${CLEANUP:-"true"}               # Flag to set yum clean up
export SLIM=${SLIM:-"false"}                    # flag to enable SLIM setup
# - EOF Environment Variables -----------------------------------------------

# - Initialization ----------------------------------------------------------
# Make sure root does not run our script
if [ ! $EUID -ne 0 ]; then
   echo "This script must not be run as root" 1>&2
   exit 1
fi

# fuser issue see MOS Note 2429708.1 OPatch Fails with Error "fuser could not be located"
running_in_docker && export OPATCH_NO_FUSER=true

# - EOF Initialization ------------------------------------------------------

# - Main --------------------------------------------------------------------
# - Install OPatch ----------------------------------------------------------
echo " - Install OPatch (${OUD_OPATCH_PKG}) ----------------------"
if [ -n "${OUD_OPATCH_PKG}" ]; then
    if get_software "${OUD_OPATCH_PKG}"; then       # Check and get binaries
        echo " - unzip ${SOFTWARE}/${OUD_OPATCH_PKG} to ${DOWNLOAD}"
        unzip -q -o ${SOFTWARE}/${OUD_OPATCH_PKG} \
            -d ${DOWNLOAD}/                         # unpack OPatch binary package
        # install the OPatch using java
        $JAVA_HOME/bin/java -jar ${DOWNLOAD}/6880880/opatch_generic.jar \
            -ignoreSysPrereqs -force \
            -silent oracle_home=${ORACLE_HOME}
        rm -rf ${DOWNLOAD}/6880880
        running_in_docker && rm -rf ${SOFTWARE}/${OUD_OPATCH_PKG}
    else
        echo "WARNING: Could not find local or remote OPatch package. Skip OPatch update."
    fi
else
    echo "INFO:    No OPatch package specified. Skip OPatch update."
fi

# - Install OUI patch -------------------------------------------------------
echo " - Install OUI patch (${OUI_PATCH_PKG}zip) -------------------"
if [ -n "${OUI_PATCH_PKG}" ]; then
    if get_software "${OUI_PATCH_PKG}"; then        # Check and get binaries
        OUI_PATCH_ID=$(echo ${OUI_PATCH_PKG}| sed -E 's/p([[:digit:]]+).*/\1/')
        echo " - unzip ${SOFTWARE}/${FMW_PATCH_PKG} to ${DOWNLOAD}"
        unzip -q -o ${SOFTWARE}/${OUI_PATCH_PKG} \
            -d ${DOWNLOAD}/                         # unpack OPatch binary package
        cd ${DOWNLOAD}/${OUI_PATCH_ID}
        ${ORACLE_HOME}/OPatch/opatch apply -silent -jre $JAVA_HOME
        # remove binary packages on docker builds
        running_in_docker && rm -rf ${SOFTWARE}/${OUI_PATCH_PKG}
        rm -rf ${DOWNLOAD}/${OUI_PATCH_ID}          # remove the binary packages
        rm -rf ${DOWNLOAD}/PatchSearch.xml          # remove the binary packages
    else
        echo "WARNING: Could not find local or remote FMW patch package. Skip FMW patch installation."
    fi
else
    echo "INFO:    No FMW patch package specified. Skip FMW patch installation."
fi

# - Install FMW patch -------------------------------------------------------
echo " - Install FMW patch (${FMW_PATCH_PKG}) -------------------"
if [ -n "${FMW_PATCH_PKG}" ]; then
    if get_software "${FMW_PATCH_PKG}"; then        # Check and get binaries
        FMW_PATCH_ID=$(echo ${FMW_PATCH_PKG}| sed -E 's/p([[:digit:]]+).*/\1/')
        echo " - unzip ${SOFTWARE}/${FMW_PATCH_PKG} to ${DOWNLOAD}"
        unzip -q -o ${SOFTWARE}/${FMW_PATCH_PKG} \
            -d ${DOWNLOAD}/                         # unpack OPatch binary package
        cd ${DOWNLOAD}/${FMW_PATCH_ID}
        ${ORACLE_HOME}/OPatch/opatch apply -silent
        # remove binary packages on docker builds
        running_in_docker && rm -rf ${SOFTWARE}/${FMW_PATCH_PKG}
        rm -rf ${DOWNLOAD}/${FMW_PATCH_ID}          # remove the binary packages
        rm -rf ${DOWNLOAD}/PatchSearch.xml          # remove the binary packages
    else
        echo "WARNING: Could not find local or remote FMW patch package. Skip FMW patch installation."
    fi
else
    echo "INFO:    No FMW patch package specified. Skip FMW patch installation."
fi

# - Install OUD patch -------------------------------------------------------
echo " - Install OUD patch (${OUD_PATCH_PKG}) -------------------"
if [ -n "${OUD_PATCH_PKG}" ]; then
    if get_software "${OUD_PATCH_PKG}"; then        # Check and get binaries
        OUD_PATCH_ID=$(echo ${OUD_PATCH_PKG}| sed -E 's/p([[:digit:]]+).*/\1/')
        echo " - unzip ${SOFTWARE}/${OUD_PATCH_PKG} to ${DOWNLOAD}"
        unzip -q -o ${SOFTWARE}/${OUD_PATCH_PKG} \
            -d ${DOWNLOAD}/                         # unpack OPatch binary package
        cd ${DOWNLOAD}/${OUD_PATCH_ID}
        ${ORACLE_HOME}/OPatch/opatch apply -silent
        # remove files on docker builds
        running_in_docker && rm -rf ${SOFTWARE}/${OUD_PATCH_PKG}
        rm -rf ${DOWNLOAD}/${OUD_PATCH_ID}          # remove the binary packages
        rm -rf ${DOWNLOAD}/PatchSearch.xml          # remove the binary packages
    else
        echo "WARNING: Could not find local or remote OUD patch package. Skip OUD patch installation."
    fi
else
    echo "INFO:    No OUD patch package specified. Skip OUD patch installation."
fi

echo " - CleanUp OUD patch installation -------------------------------------"
# Temp locations
rm -rf ${DOWNLOAD}/*
rm -rf /tmp/*.rsp
rm -rf /tmp/InstallActions*
rm -rf /tmp/CVU*oracle
rm -rf /tmp/OraInstall*

running_in_docker && rm -rf ${ORACLE_HOME}/.patch_storage       # remove patch storage
running_in_docker && rm -rf ${ORACLE_HOME}/inventory/backup/*   # OUI backup

# remove all the logs....
find ${ORACLE_INVENTORY} -type f -name *.log -exec rm {} \;
find ${ORACLE_BASE}/product -type f -name *.log -exec rm {} \;
# --- EOF --------------------------------------------------------------------