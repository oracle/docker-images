#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: create_oud_instance.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: Helper script to create the OUD instance 
# Notes......: Script to create an OUD instance. If configuration files are
#              provided, the will be used to configure the instance.
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

# Default values for the instance home and admin directory
export OUD_INSTANCE_ADMIN=${OUD_INSTANCE_ADMIN:-${ORACLE_DATA}/admin/${OUD_INSTANCE}}
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"$ORACLE_DATA/instances"}
export OUD_INSTANCE_HOME=${OUD_INSTANCE_HOME:-"${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"}

# Default values for host and ports
export HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)   # Hostname
export PORT=${PORT:-1389}                               # Default LDAP port
export PORT_SSL=${PORT_SSL:-1636}                       # Default LDAPS port
export PORT_REP=${PORT_REP:-8989}                       # Default replication port
export PORT_ADMIN=${PORT_ADMIN:-4444}                   # Default admin port

# Default value for the directory
export ADMIN_USER=${ADMIN_USER:-'cn=Directory Manager'} # Default directory admin user
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-""}             # Default directory admin password
export PWD_FILE=${PWD_FILE:-${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt}
export BASEDN=${BASEDN:-'dc=example,dc=com'}          # Default directory base DN
export SAMPLE_DATA=${SAMPLE_DATA:-'TRUE'}               # Flag to load sample data
export OUD_PROXY=${OUD_PROXY:-'FALSE'}                  # Flag to create proxy instance

# default folder for OUD instance init scripts
export OUD_INSTANCE_INIT=${OUD_INSTANCE_INIT:-$ORACLE_DATA/scripts}
# - EOF Environment Variables -----------------------------------------------

# Normalize CREATE_INSTANCE
export OUD_PROXY=$(echo $OUD_PROXY| sed 's/^false$/0/gi')
export OUD_PROXY=$(echo $OUD_PROXY| sed 's/^true$/1/gi')

# Normalize SAMPLE_DATA and DIRECTORY_DATA
DIRECTORY_DATA="--addBaseEntry"
if [ -z ${SAMPLE_DATA} ]; then
    echo "SAMPLE_DATA is not set. Create base entry $BASEDN"
    DIRECTORY_DATA="--addBaseEntry"
elif [[ "${SAMPLE_DATA}" =~ ^[0-9]+$ ]]; then
    echo "SAMPLE_DATA is set to a number. Creating $SAMPLE_DATA sample entries"
    DIRECTORY_DATA="--sampleData $SAMPLE_DATA"
elif [[ "${SAMPLE_DATA^^}" =~ ^TRUE$ ]]; then
    echo "SAMPLE_DATA is true. Creating 100 sample entries"
    DIRECTORY_DATA="--sampleData 100"
else
    echo "SAMPLE_DATA is undefined. Create base entry $BASEDN"
    DIRECTORY_DATA="--addBaseEntry"
fi

echo "--- Setup OUD environment on volume ${ORACLE_DATA} ----------------------"
# create instance directories on volume
mkdir -v -p ${ORACLE_DATA}
for i in admin backup etc instances domains log scripts; do
    mkdir -v -p ${ORACLE_DATA}/${i}
done
mkdir -v -p ${OUD_INSTANCE_ADMIN}/etc

# create oudtab file for OUD Base
OUDTAB=${ORACLE_DATA}/etc/oudtab
echo "${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:OUD" >>${OUDTAB}

# generate a password
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
    echo "    Oracle Unified Directory Server auto generated instance"
    echo "    admin password :"
    echo "    ----> Directory Admin : ${ADMIN_USER} "
    echo "    ----> Admin password  : $s"
    echo "---------------------------------------------------------------"
else
    s=${ADMIN_PASSWORD}
    echo "---------------------------------------------------------------"
    echo "    Oracle Unified Directory Server auto generated instance"
    echo "    admin password :"
    echo "    ----> Directory Admin : ${ADMIN_USER} "
    echo "    ----> Admin password  : $s"
    echo "---------------------------------------------------------------"
fi

# write password file
echo "$s" > ${PWD_FILE}

# set instant init location create folder if it does exists
if [ -d "${OUD_INSTANCE_ADMIN}/create" ]; then
    OUD_INSTANCE_INIT="${OUD_INSTANCE_ADMIN}/create"
else
    OUD_INSTANCE_INIT="${OUD_INSTANCE_INIT}/setup"
fi

echo "--- Create OUD instance ---------------------------------------"
echo "  OUD_INSTANCE       = ${OUD_INSTANCE}"
echo "  OUD_INSTANCE_BASE  = ${OUD_INSTANCE_BASE}"
echo "  OUD_INSTANCE_ADMIN = ${OUD_INSTANCE_ADMIN}"
echo "  OUD_INSTANCE_INIT  = ${OUD_INSTANCE_INIT}"
echo "  OUD_INSTANCE_HOME  = ${OUD_INSTANCE_HOME}"
echo "  PORT               = ${PORT}"
echo "  PORT_SSL           = ${PORT_SSL}"
echo "  PORT_REP           = ${PORT_REP}"
echo "  PORT_ADMIN         = ${PORT_ADMIN}"
echo "  ADMIN_USER         = ${ADMIN_USER}"
echo "  BASEDN             = ${BASEDN}"
echo "  SAMPLE_DATA        = ${SAMPLE_DATA}"
echo "  OUD_PROXY          = ${OUD_PROXY}"
echo ""

if [ ${OUD_PROXY} -eq 0 ]; then
# Create an directory
    echo "--- Create regular OUD instance (${OUD_INSTANCE}) ----------------------"
    ${ORACLE_BASE}/product/${ORACLE_HOME_NAME}/oud/oud-setup \
        --cli \
        --instancePath "${OUD_INSTANCE_HOME}/OUD" \
        --rootUserDN "${ADMIN_USER}" \
        --rootUserPasswordFile "${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt" \
        --adminConnectorPort ${PORT_ADMIN} \
        --ldapPort ${PORT} \
        --ldapsPort ${PORT_SSL} \
        --generateSelfSignedCertificate \
        --enableStartTLS \
        --hostname ${HOST} \
        --baseDN "${BASEDN}" \
        ${DIRECTORY_DATA} \
        --serverTuning jvm-default \
        --offlineToolsTuning autotune \
        --no-prompt \
        --noPropertiesFile
    if [ $? -eq 0 ]; then
        echo "--- Successfully created regular OUD instance (${OUD_INSTANCE}) --------"
        # Execute custom provided setup scripts
        
        ${DOCKER_SCRIPTS}/config_oud_instance.sh ${OUD_INSTANCE_INIT}
    else
        echo "--- ERROR creating regular OUD instance (${OUD_INSTANCE}) --------------"
        exit 1
    fi
elif [ ${OUD_PROXY} -eq 1 ]; then
    echo "--- Create OUD proxy instance (${OUD_INSTANCE}) ------------------------------"
    ${ORACLE_BASE}/product/${ORACLE_HOME_NAME}/oud/oud-proxy-setup \
        --cli \
        --instancePath "${OUD_INSTANCE_HOME}/OUD" \
        --rootUserDN "${ADMIN_USER}" \
        --rootUserPasswordFile "${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt" \
        --adminConnectorPort ${PORT_ADMIN} \
        --ldapPort ${PORT} \
        --ldapsPort ${PORT_SSL} \
        --generateSelfSignedCertificate \
        --enableStartTLS \
        --hostname ${HOST} \
        --no-prompt \
        --noPropertiesFile
    if [ $? -eq 0 ]; then
        echo "--- Successfully created OUD proxy instance (${OUD_INSTANCE}) ----------------"
        # Execute custom provided setup scripts
        
        ${DOCKER_SCRIPTS}/config_oud_instance.sh ${OUD_INSTANCE_INIT}
    else
        echo "--- ERROR creating OUD proxy instance (${OUD_INSTANCE}) ----------------------"
        exit 1
    fi
fi
# --- EOF -------------------------------------------------------------------