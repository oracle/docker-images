#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 01_setup_os_oud.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.09.27
# Revision...: 
# Purpose....: Script to configure OEL for Oracle Unified Directory installations.
# Notes......: Script would like to be executed as root :-).
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

# define oradba specific variables
export ORADBA_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export ORADBA_BASE="$(dirname ${ORADBA_BIN})"
export ORADBA_RSP="${ORADBA_BASE}/rsp"          # oradba init response file folder

# define Oracle specific variables
export ORACLE_ROOT=${ORACLE_ROOT:-"/u00"}       # root folder for ORACLE_BASE and binaries
export ORACLE_DATA=${ORACLE_DATA:-"/u01"}       # Oracle data folder eg volume for docker
export ORACLE_BASE=${ORACLE_BASE:-"${ORACLE_ROOT}/app/oracle"}
export ORACLE_INVENTORY=${ORACLE_INVENTORY:-"${ORACLE_ROOT}/app/oraInventory"}

# define generic variables for software, download etc
export OPT_DIR=${OPT_DIR:-"/opt"}
export SOFTWARE=${SOFTWARE:-"${OPT_DIR}/stage"} # local software stage folder
export DOWNLOAD=${DOWNLOAD:-"/tmp/download"}    # temporary download location
export CLEANUP=${CLEANUP:-true}                 # Flag to set yum clean up
# - EOF Environment Variables -----------------------------------------------

# Make sure only root can run our script
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# create necessary groups
groupadd --gid 1010 oinstall

# create the oracle OS user
useradd --create-home --gid oinstall \
    --shell /bin/bash oracle

# do some stuff on none docker environments
if [ ! running_in_docker ]; then
    # set the default password for the oracle user
    echo "manager" | passwd --stdin oracle

    # copy autorized keys 
    mkdir -p /home/oracle/.ssh/
    cp ${HOME}/.ssh/authorized_keys /home/oracle/.ssh/
    chown oracle:oinstall -R /home/oracle/.ssh
    chmod 700 /home/oracle/.ssh/

    # remove openJDK
    ${YUM} erase -y java-1.8.0-openjdk java-1.8.0-openjdk-headless
fi

# show what we will create later on...
echo "ORACLE_ROOT       =${ORACLE_ROOT}" && \
echo "ORACLE_DATA       =${ORACLE_DATA}" && \
echo "ORACLE_BASE       =${ORACLE_BASE}" && \
echo "ORACLE_INVENTORY  =${ORACLE_INVENTORY}" && \
echo "SOFTWARE          =${SOFTWARE}" && \
echo "DOWNLOAD          =${DOWNLOAD}" 

# create the directory tree
install --owner oracle --group oinstall --mode=775 --verbose --directory \
        ${ORACLE_ROOT} \
        ${ORACLE_DATA} \
        ${ORACLE_BASE} \
        ${ORACLE_INVENTORY} \
        ${SOFTWARE} \
        ${DOWNLOAD}

# create a softlink for init script usually just used for docker init
running_in_docker && ln -s ${ORACLE_DATA}/scripts /docker-entrypoint-initdb.d

# limit installation language / locals to EN
echo "%_install_langs   en" >>/etc/rpm/macros.lang
#YUM="yum --disablerepo=ol7_developer"
YUM="yum"
# upgrade the installation
${YUM} upgrade -y

# check for legacy yum upgrade
if [ -f "/usr/bin/ol_yum_configure.sh" ]; then
    echo "found /usr/bin/ol_yum_configure.sh "
    /usr/bin/ol_yum_configure.sh
    ${YUM} upgrade -y
fi

# install basic utilities
${YUM} install -y libaio gzip tar zip unzip

# clean up yum repository
if [ "${CLEANUP^^}" == "TRUE" ]; then
    echo "clean up yum cache"
    ${YUM} clean all 
    rm -rf /var/cache/yum
else
    echo "yum cache is not cleaned up"
fi

# create a bunch of other directories
mkdir -p ${ORACLE_BASE}/etc
mkdir -p ${ORACLE_BASE}/tmp
mkdir -p ${ORACLE_DATA}/scripts
mkdir -p ${ORADBA_BIN}
mkdir -p ${ORADBA_RSP}

# change owner of ORACLE_BASE and ORACLE_INVENTORY
chown -R oracle:oinstall ${ORACLE_BASE} ${ORACLE_INVENTORY} ${SOFTWARE}

# add 3DES_EDE_CBC for Oracle EUS
JAVA_SECURITY=$(find /usr/java -name java.db 2>/dev/null)
if [ ! -z ${JAVA_SECURITY} ] && [ -f ${JAVA_SECURITY} ]; then
    sed -i 's/, 3DES_EDE_CBC//' ${JAVA_SECURITY}
fi
# --- EOF --------------------------------------------------------------------