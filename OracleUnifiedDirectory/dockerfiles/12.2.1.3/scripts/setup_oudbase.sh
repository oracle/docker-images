#!/bin/bash
# -----------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------------
# Name.......: setup_oudbase.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.04.11
# Revision...:  
# Purpose....: Script to download and install latest version of oudbase
# Notes......: The script does download the latest version of OUD Base from
#              GitHub and install it in ${ORACLE_BASE}
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# -----------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# -----------------------------------------------------------------------------

# - Customization -----------------------------------------------------------
DOWNLOAD="/tmp/download"
# oudbase install script
OUDBASE_PKG="oudbase_install.sh"
# OUD base GitHub download URL
OUDBASE_URL=$(curl -s https://api.github.com/repos/oehrlis/oudbase/releases/latest \
        | grep "browser_download_url.*${OUDBASE_PKG}" \
        | cut -d: -f 2,3 \
        | tr -d \" )
# - End of Customization ----------------------------------------------------

# geht the OUD base install package
curl -f --location-trusted ${OUDBASE_URL} -o ${DOWNLOAD}/${OUDBASE_PKG}

#adapt permissions
chmod 755 ${DOWNLOAD}/${OUDBASE_PKG}

# install OUD base
${DOWNLOAD}/${OUDBASE_PKG} -va -b ${ORACLE_BASE} -m ${ORACLE_HOME} -d ${ORACLE_DATA} && \

# clean up
rm -rf ${DOWNLOAD}/${OUDBASE_PKG} ${DOWNLOAD}/oudbase_install.log

# --- EOF -------------------------------------------------------------------