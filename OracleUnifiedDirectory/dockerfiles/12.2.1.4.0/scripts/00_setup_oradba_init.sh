#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 00_setup_oradba_init.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.09.27
# Revision...: 
# Purpose....: Script to initialize and install oradba init scripts.
# Notes......: When executed, the oradba init scripts will be downloaded from 
#              github and installed. If the file is just sourced, only the 
#              common functions and environment variables will be set.
#              Script would like to be executed as root or source as 
#              anybody :-) 
# Reference..: This script is a copy from the Git repository 
#              https://github.com/oehrlis/oradba_init 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
# - Customization -----------------------------------------------------------
# - just add/update any kind of customized environment variable here
export OPT_DIR="/opt"
export ORACLE_ROOT=${ORACLE_ROOT:-"/u00"}   # root folder for ORACLE_BASE and binaries
export ORACLE_DATA=${ORACLE_DATA:-"/u01"}   # Oracle data folder eg volume for docker
export ORACLE_ARCH=${ORACLE_ARCH:-"/u02"}   # Oracle arch folder eg volume for docker
export ORACLE_BASE=${ORACLE_BASE:-${ORACLE_ROOT}/app/oracle}
export ORACLE_INVENTORY=${ORACLE_INVENTORY:-${ORACLE_ROOT}/app/oraInventory}
# - End of Customization ----------------------------------------------------

# - Environment Variables ---------------------------------------------------
# define the oradba url and package name
export GITHUB_URL="https://codeload.github.com/oehrlis/oradba_init/zip/master"
export ORADBA_PKG="oradba_init.zip"

# define the defaults for software, download etc
export OPT_DIR=${OPT_DIR:-"/opt"}
export SOFTWARE=${SOFTWARE:-"${OPT_DIR}/stage"} # local software stage folder
export SOFTWARE_REPO=${SOFTWARE_REPO:-""}       # URL to software for curl fallback
export DOWNLOAD=${DOWNLOAD:-"/tmp/download"}    # temporary download location
export CLEANUP=${CLEANUP:-true}                 # Flag to set yum clean up
# - EOF Environment Variables -----------------------------------------------

# - Functions ---------------------------------------------------------------
function get_software {
# ---------------------------------------------------------------------------
# Purpose....: Verify if the software package is available if not try to 
#              download it from $SOFTWARE_REPO
# ---------------------------------------------------------------------------
    PKG=$1
    if [ ! -s "${SOFTWARE}/${PKG}" ]; then
        if [ ! -z "${SOFTWARE_REPO}" ]; then
            echo "INFO:    Try to download ${PKG} from ${SOFTWARE_REPO}"
            curl -f ${SOFTWARE_REPO}/${PKG} -o ${SOFTWARE}/${PKG} 2>&1
            CURL_ERR=$?
            if [ ${CURL_ERR} -ne 0 ]; then
                echo "WARNING: Unable to access software repository or ${PKG} (curl error ${CURL_ERR})"
                return 1
            fi
        else
            echo "WARNING: No software repository specified"
            return 1
        fi
    else
        echo "Found package ${PKG} for installation."
        return 0
    fi
}

function running_in_docker() {
# ---------------------------------------------------------------------------
# Purpose....:  Function for checking whether the process is running in a 
#               container. It return 0 if YES or 1 if NOT.
# ---------------------------------------------------------------------------
    if [ -e /proc/self/cgroup ]; then
        awk -F/ '$2 == "docker"' /proc/self/cgroup | read
    else
        return 1
    fi
}
# - EOF Functions -----------------------------------------------------------

# check if script is sourced and return/exit
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo " - Set common functions and variables ---------------------------------"
    return
fi

# Still here, seems that script is executed
# Make sure only root can run our script
if [ $EUID -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# create a software depot
mkdir -p ${SOFTWARE}
chmod 777 ${SOFTWARE}

# - Get oradba init scripts -----------------------------------------------
echo " - Get oradba init scripts --------------------------------------------"
mkdir -p ${DOWNLOAD}                                    # create download folder
curl -Lf ${GITHUB_URL} -o ${DOWNLOAD}/${ORADBA_PKG}

# check if we do have an unzip command
if [ ! -z $(command -v unzip) ]; then 
    # unzip seems to be available
    unzip -o ${DOWNLOAD}/${ORADBA_PKG} -d /opt          # unzip scripts
else 
    # missing unzip fallback to a simple phyton script as python seems
    # to be available on Docker image oraclelinx:7-slim
    echo "no unzip available, fallback to python script"
    echo "import zipfile" >${DOWNLOAD}/unzipfile.py
    echo "with zipfile.ZipFile('${DOWNLOAD}/${ORADBA_PKG}', 'r') as z:" >>${DOWNLOAD}/unzipfile.py
    echo "   z.extractall('${OPT_DIR}')">>${DOWNLOAD}/unzipfile.py
    python ${DOWNLOAD}/unzipfile.py

    # adjust file mods
    find ${OPT_DIR} -type f -name *.sh -exec chmod 755 {} \;
fi

mv ${OPT_DIR}/oradba_init-master ${OPT_DIR}/oradba      # get rid of master folder
mv ${OPT_DIR}/oradba/README.md ${OPT_DIR}/oradba/doc    # move documentation
rm ${OPT_DIR}/oradba/.gitignore                         # remove gitignore
rm -rf ${DOWNLOAD}                                      # clean up
# --- EOF --------------------------------------------------------------------