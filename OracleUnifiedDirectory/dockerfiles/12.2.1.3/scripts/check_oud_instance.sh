#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: check_oud_Instance.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: check the status of the OUD instance for docker HEALTHCHECK 
# Notes......: Script is a wrapper for oud_status.sh. It makes sure, that the 
#              status of the docker OUD instance is checked and the exit code
#              of oud_status.sh is docker compliant (0 or 1).
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# - Environment Variables ---------------------------------------------------
# - Set default values for environment variables if not yet defined. 
# ---------------------------------------------------------------------------
# Default name for OUD instance
export OUD_INSTANCE=${OUD_INSTANCE:-oud_docker}

# OUD instance base directory
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"$ORACLE_DATA/instances"}

# Default values for the instance home and admin directory
export OUD_INSTANCE_HOME=${OUD_INSTANCE_HOME:-"${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"}

# Default value for the directory
export ADMIN_USER=${ADMIN_USER:-'cn=Directory Manager'} # Default directory admin user
export PWD_FILE=${PWD_FILE:-${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt}
export TMP_DIRECTORY="/tmp"
export TMP_FILE="${TMP_DIRECTORY}/$(basename $0).$$"
# - EOF Environment Variables -----------------------------------------------

# check if password file is available
if [ ! -e ${PWD_FILE} ]; then
    echo "$0: Can not find password file ${PWD_FILE}"
    exit 1
fi

# Run status on OUD Instance
${OUD_INSTANCE_HOME}/OUD/bin/status --script-friendly --no-prompt \
    --noPropertiesFile --bindDN "${ADMIN_USER}" --bindPasswordFile ${PWD_FILE} \
    --trustAll >${TMP_FILE} 2>&1
OUD_ERROR=$?

# handle errors from OUD status
if [ ${OUD_ERROR} -gt 0 ]; then
    echo "$0: Error ${OUD_ERROR} running status command ${OUD_INSTANCE_HOME}/OUD/bin/status"
    exit 1
fi

 # adjust temp file 
# and add a - at the end
sed -i 's/^$/-/' ${TMP_FILE}
# join Backend ID with multiple lines
sed -i '/OracleContext for$/{N;s/\n/ /;}' ${TMP_FILE}
# join Base DN with multiple lines
sed -i '/^Base DN:$/{N;s/\n/                      /;}' ${TMP_FILE}

# check Server Run Status
if [ $(grep -ic 'Server Run Status: Started' ${TMP_FILE}) -eq 0 ]; then
    echo "$0: Error OUD Instance ${OUD_INSTANCE} not running"
    exit 1
fi

# check if connection handler are enabled
for i in LDAP LDAPS; do
    AWK_OUT=$(awk 'BEGIN{RS="\n-\n";FS="\n";IGNORECASE=1; Error=51} $1 ~ /^Address/ && $2 ~ /\<'${i}'\>/ {if ($3 ~ /\<Enabled\>/) Error=0; } END{exit Error}' ${TMP_FILE} )
    OUD_ERROR=$?
    if [ ${OUD_ERROR} -eq 51 ]; then
        echo "$0: Connection Handler ${i} is not enabled on ${OUD_INSTANCE}"
        exit 1
    fi
done

if [ -e ${TMP_FILE} ]; then
    rm ${TMP_FILE} 2>/dev/null
    # remove oud status temp file due to an oracle Bug
    rm /tmp/oud-status*.log 2>/dev/null
fi

# if we came that far just exit with 0
exit 0
# --- EOF -------------------------------------------------------------------