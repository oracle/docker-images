#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 72_create_oudsm_domain.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: Helper script to create the OUDSM domain  
# Notes......: Script to create an OUDSM domain.
# Reference..: This script is a copy from the Git repository 
#              https://github.com/oehrlis/oradba_init 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# TODO.......:
# ---------------------------------------------------------------------------

# - Script Variables --------------------------------------------------------
# - Set script names for miscellaneous start, check and config scripts.
# ---------------------------------------------------------------------------
# Default name for OUD instance
# source genric environment variables and functions
source "$(dirname ${BASH_SOURCE[0]})/00_setup_oradba_init.sh"

# define oradba specific variables
export ORADBA_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export ORADBA_BASE="$(dirname ${ORADBA_BIN})"
export CREATE_SCRIPT_PYTHON=${CREATE_SCRIPT_PYTHON:-"72_create_oudsm_domain.py"}
# - EOF Script Variables ----------------------------------------------------

# - Environment Variables ---------------------------------------------------
# - Set default values for environment variables if not yet defined. 
# ---------------------------------------------------------------------------
# Default name for OUD instance
export DOMAIN_NAME=${DOMAIN_NAME:-oudsm_domain}

# Default values for the instance home and admin directory
export OUD_INSTANCE_ADMIN=${OUD_INSTANCE_ADMIN:-${ORACLE_DATA}/admin/${DOMAIN_NAME}}
export OUDSM_DOMAIN_BASE=${OUDSM_DOMAIN_BASE:-"$ORACLE_DATA/domains"}
export DOMAIN_HOME=${OUDSM_DOMAIN_BASE}/${DOMAIN_NAME}

# Default values for host and ports
export HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)   # Hostname
export PORT=${PORT:-7001}                               # Default HTTP port
export PORT_SSL=${PORT_SSL:-7002}                       # Default HTTPS port

# Default value for the directory
export ADMIN_USER=${ADMIN_USER:-'weblogic'} # Default directory admin user
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-""}             # Default directory admin password
export PWD_FILE=${PWD_FILE:-${OUD_INSTANCE_ADMIN}/etc/${DOMAIN_NAME}_pwd.txt}
# - EOF Environment Variables -----------------------------------------------

echo "--- Setup OUDSM environment on volume ${ORACLE_DATA} --------------------"

# create instance directories on volume
mkdir -v -p ${ORACLE_DATA}
for i in admin backup etc instances domains log scripts; do
    mkdir -v -p ${ORACLE_DATA}/${i}
done
mkdir -v -p ${OUD_INSTANCE_ADMIN}/etc
mkdir -v -p ${OUD_INSTANCE_ADMIN}/create
cp ${ORADBA_BIN}/${CREATE_SCRIPT_PYTHON} ${OUD_INSTANCE_ADMIN}/create/${CREATE_SCRIPT_PYTHON}
# create oudtab file for OUD Base
OUDTAB=${ORACLE_DATA}/etc/oudtab
echo "${DOMAIN_NAME}:${PORT}:${PORT_SSL}:::OUDSM" >>${OUDTAB}

if [ -z ${ADMIN_PASSWORD} ]; then
    # Auto generate Oracle WebLogic Server admin password
    while true; do
        s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 10 | head -n 1)
        if [[ ${#s} -ge 10 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
            break
        else
            echo "Password does not Match the criteria, re-generating..."
        fi
    done
    echo "---------------------------------------------------------------"
    echo "    Oracle WebLogic Server Auto Generated OUDSM Domain:"
    echo "    ----> 'weblogic' admin password: $s"
    echo "---------------------------------------------------------------"
else
    s=${ADMIN_PASSWORD}
    echo "---------------------------------------------------------------"
    echo "    Oracle WebLogic Server Auto Generated OUDSM Domain:"
    echo "    ----> 'weblogic' admin password: $s"
    echo "---------------------------------------------------------------"
fi 
sed -i -e "s|ADMIN_PASSWORD|$s|g" ${OUD_INSTANCE_ADMIN}/create/${CREATE_SCRIPT_PYTHON}

echo "--- Create WebLogic Server Domain (${DOMAIN_NAME}) -----------------------------"
echo "  DOMAIN_NAME=${DOMAIN_NAME}"
echo "  DOMAIN_HOME=${DOMAIN_HOME}"
echo "  PORT=${PORT}"
echo "  PORT_SSL=${PORT_SSL}"
echo "  ADMIN_USER=${ADMIN_USER}"

# Create an empty domain
${ORACLE_HOME}/oracle_common/common/bin/wlst.sh \
    -skipWLSModuleScanning ${OUD_INSTANCE_ADMIN}/create/${CREATE_SCRIPT_PYTHON}

if [ $? -eq 0 ]; then
    echo "--- Successfully created WebLogic Server Domain (${DOMAIN_NAME}) --------------"
else 
    echo "--- ERROR creating WebLogic Server Domain (${DOMAIN_NAME}) --------------------"
fi
${DOMAIN_HOME}/bin/setDomainEnv.sh
# --- EOF -------------------------------------------------------------------
