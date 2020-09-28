#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 60_start_oud_instance.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...:
# Purpose....: Helper script to start the OUD instance
# Notes......: Script does look for the config.ldif. If it does not exist
#              it assume that the container is started the first time. A new
#              OUD instance will be created. If CREATE_INSTANCE is set to false
#              no instance will be created.
# Reference..: This script is a copy from the Git repository 
#              https://github.com/oehrlis/oradba_init 
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

# Flag to create instance on first boot
export CREATE_INSTANCE=${CREATE_INSTANCE:-'TRUE'}

# OUD instance base directory
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"$ORACLE_DATA/instances"}

# OUD instance home directory
export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
# - EOF Environment Variables -----------------------------------------------

# - Script Variables --------------------------------------------------------
# - Set script names for miscellaneous start, check and config scripts.
# ---------------------------------------------------------------------------
# Default name for OUD instance
# source genric environment variables and functions
source "$(dirname ${BASH_SOURCE[0]})/00_setup_oradba_init.sh"

# define oradba specific variables
export ORADBA_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export ORADBA_BASE="$(dirname ${ORADBA_BIN})"
export CREATE_SCRIPT=${CREATE_SCRIPT:-"62_create_oud_instance.sh"}
export CHECK_SCRIPT=${CHECK_SCRIPT:-"64_check_oud_instance.sh"}
# - EOF Script Variables ----------------------------------------------------

# ---------------------------------------------------------------------------
# SIGINT handler
# ---------------------------------------------------------------------------
function int_oud() {
    echo "---------------------------------------------------------------"
    echo "SIGINT received, shutting down OUD instance!"
    echo "---------------------------------------------------------------"
    ${OUD_INSTANCE_HOME}/OUD/bin/stop-ds >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# SIGTERM handler
# ---------------------------------------------------------------------------
function term_oud() {
    echo "---------------------------------------------------------------"
    echo "SIGTERM received, shutting down OUD instance!"
    echo "---------------------------------------------------------------"
    ${OUD_INSTANCE_HOME}/OUD/bin/stop-ds >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# SIGKILL handler
# ---------------------------------------------------------------------------
function kill_oud() {
    echo "---------------------------------------------------------------"
    echo "SIGKILL received, shutting down OUD instance!"
    echo "---------------------------------------------------------------"
    kill -9 $childPID
}

# Set SIGINT handler
trap int_oud SIGINT

# Set SIGTERM handler
trap term_oud SIGTERM

# Set SIGKILL handler
trap kill_oud SIGKILL

# Normalize CREATE_INSTANCE
export CREATE_INSTANCE=$(echo $CREATE_INSTANCE| sed 's/^false$/0/gi')
export CREATE_INSTANCE=$(echo $CREATE_INSTANCE| sed 's/^true$/1/gi')

echo "--- Seeking for an OUD environment on volume ${ORACLE_DATA} -------------"
# check if config.ldif does exists
if [ -f ${OUD_INSTANCE_HOME}/OUD/config/config.ldif ]; then
    # check version of existing instance
    echo "---------------------------------------------------------------"
    echo "   OUD instance (${OUD_INSTANCE}) system info:"
    echo "---------------------------------------------------------------"
    ${OUD_INSTANCE_HOME}/OUD/bin/start-ds -F
    
    # Start existing OUD instance
    echo "---------------------------------------------------------------"
    echo "   Start OUD instance (${OUD_INSTANCE}):"
    echo "---------------------------------------------------------------"
    ${OUD_INSTANCE_HOME}/OUD/bin/start-ds
    if [ $? -eq 1 ]; then
        echo "---------------------------------------------------------------"
        echo "   OUD instance (${OUD_INSTANCE}) needs to be upgraded first:"
        echo "---------------------------------------------------------------"
        ${OUD_INSTANCE_HOME}/OUD/bin/start-ds --upgrade
        
        echo "---------------------------------------------------------------"
        echo "   Start OUD instance (${OUD_INSTANCE}) after upgrad:"
        echo "---------------------------------------------------------------"
        ${OUD_INSTANCE_HOME}/OUD/bin/start-ds
    fi
    elif [ ${CREATE_INSTANCE} -eq 1 ]; then
    echo "---------------------------------------------------------------"
    echo "   Create OUD instance (${OUD_INSTANCE}):"
    echo "---------------------------------------------------------------"
    # CREATE_INSTANCE is true, therefore we will create new OUD instance
    ${ORADBA_BIN}/${CREATE_SCRIPT}
    
    if [ $? -eq 0 ]; then
        # restart OUD instance
        ${OUD_INSTANCE_HOME}/OUD/bin/stop-ds --restart
    fi
else
    echo "---------------------------------------------------------------"
    echo "   WARNING: OUD config.ldif does not exist and CREATE_INSTANCE "
    echo "   is false. OUD instance has to be created manually using"
    echo "   oud_setup or oud-proxy-setup via cli"
    echo "---------------------------------------------------------------"
fi

# Check whether OUD instance is up and running
${ORADBA_BIN}/${CHECK_SCRIPT}
if [ $? -eq 0 ]; then
    echo "---------------------------------------------------------------"
    echo "   OUD instance is ready to use:"
    echo "   Instance Name      : ${OUD_INSTANCE}"
    echo "   Instance Home (ok) : ${OUD_INSTANCE_HOME}"
    echo "   Oracle Home        : ${ORACLE_BASE}/product/${ORACLE_HOME_NAME}"
    echo "   Instance Status    : up"
    echo "   LDAP Port          : ${PORT}"
    echo "   LDAPS Port         : ${PORT_SSL}"
    echo "   Admin Port         : ${PORT_ADMIN}"
    echo "   Replication Port   : ${PORT_REP}"
    echo "---------------------------------------------------------------"
fi

# Tail on server log and wait (otherwise container will exit)
mkdir -p ${OUD_INSTANCE_HOME}/OUD/logs
touch ${OUD_INSTANCE_HOME}/OUD/logs/server.out
echo "---------------------------------------------------------------"
echo "   Tail output of OUD (${OUD_INSTANCE}) server.out logfile:"
echo "---------------------------------------------------------------"
tail -f ${OUD_INSTANCE_HOME}/OUD/logs/server.out &

childPID=$!
wait $childPID
# --- EOF -------------------------------------------------------------------