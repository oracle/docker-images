# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.10.12
# Purpose....: This Dockerfile is to build Oracle Unifid Directory
# Notes......: ENV settings and their order is optimized for using build cache.
# Reference..: This Dockerfile is originated in the Git repositoy 
#              https://github.com/oehrlis/docker
# License....: Licensed under the Universal Permissive License v 1.0 as
#              shown at http://oss.oracle.com/licenses/upl.
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ----------------------------------------------------------------------

# Pull base image
# ----------------------------------------------------------------------
FROM oracle/serverjre:8 as base

# Maintainer
# ----------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@trivadis.com"

# Build Argumenta
# ----------------------------------------------------------------------
# These build arguments allows a couple of customizations during build
ARG   ORACLE_ROOT
ARG   ORACLE_DATA
ARG   ORACLE_BASE
ARG   ORAREPO

# Environment Variable
# ----------------------------------------------------------------------
# Environment variables required for this build Change them carefully and wise!
# ORAREPO is an environment variable for a software repository host. If omitted
# installation scripts will use the local software
ENV   ORAREPO=${ORAREPO:-orarepo}

# Software stage area, repository, binary packages and patchs
ENV   DOWNLOAD="/tmp/download" \
      SOFTWARE="/opt/stage" \
      SOFTWARE_REPO="http://$ORAREPO" \
      DOCKER_SCRIPTS="/opt/docker/bin" \
      ORADBA_SCRIPTS="/opt/oradba/bin" \
      ORADBA_RSP="/opt/oradba/rsp" \
      ORACLE_ROOT=${ORACLE_ROOT:-/u00} \
      ORACLE_DATA=${ORACLE_DATA:-/u01} 

# scripts to build this image
ENV   SETUP_INIT="00_setup_oradba_scripts.sh" \
      SETUP_OS="01_setup_os_oud.sh" 

# Use second ENV so that variable get substituted
ENV   ORACLE_BASE=${ORACLE_BASE:-$ORACLE_ROOT/app/oracle}

# RUN as user root
# ----------------------------------------------------------------------
# create a couple of directories used during build
RUN   mkdir -p ${DOWNLOAD} ${ORADBA_SCRIPTS} ${ORADBA_RSP} ${DOCKER_SCRIPTS}

# Copy scripts / config to image
# ----------------------------------------------------------------------
COPY  scripts/* ${ORADBA_SCRIPTS}/
COPY  config/*.tmpl ${ORADBA_RSP}/
# Copy adjusted java.security file. This is required by Oracle EUS
COPY  config/java.security /usr/java/latest/jre/lib/security/java.security

# Setup OS using OraDBA init script
RUN   ${ORADBA_SCRIPTS}/${SETUP_OS}

# Set Version specific stuff
# ----------------------------------------------------------------------
# scripts to build and run this container
ENV SETUP_OUD="10_setup_oud.sh" \
    SETUP_OUDBASE="20_setup_oudbase.sh" \
    START_SCRIPT="60_start_oud_instance.sh" \
    CHECK_SCRIPT="64_check_oud_instance.sh" 

# Define the OUD software packages and patch's.
ENV OUD_BASE_PKG="p30188352_122140_Generic.zip" \
    OUD_PATCH_PKG="" \
    OUD_OPATCH_PKG=""

# stuff to setup and run an OUD instance
ENV OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-$ORACLE_DATA/instances} \
    OUD_INSTANCE=${OUD_INSTANCE:-oud_docker} \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    OPENDS_JAVA_ARGS="-Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" \
    ORACLE_HOME_NAME="fmw12.2.1.4.0" \
    OUD_VERSION="12" \
    PORT="${PORT:-1389}" \
    PORT_SSL="${PORT_SSL:-1636}" \
    PORT_HTTP="${PORT_HTTP:-8080}" \
    PORT_HTTPS="${PORT_HTTPS:-10443}" \
    PORT_REP="${PORT_REP:-8989}" \
    PORT_ADMIN="${PORT_ADMIN:-4444}" \
    PORT_ADMIN_HTTP="${PORT_ADMIN_HTTP:-8444}"

# same same but different...
# third ENV so that variable get substituted
ENV PATH=${PATH}:"${OUD_INSTANCE_HOME}/OUD/bin:${ORACLE_BASE}/product/${ORACLE_HOME_NAME}/oud/bin:${ORADBA_SCRIPTS}:${DOCKER_SCRIPTS}" \
    ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_HOME_NAME}

# New stage for installing the oud binaries
# ----------------------------------------------------------------------
FROM  base AS builder

# COPY oud software 
COPY  --chown=oracle:oinstall software/*zip* "${SOFTWARE}/"

# RUN as oracle
# Switch to user oracle, oracle software as to be installed with regular user
# ----------------------------------------------------------------------
USER  oracle
RUN   ${ORADBA_SCRIPTS}/${SETUP_OUD}

# get the latest OUD base environment scripts from GitHub and install them
RUN   ${ORADBA_SCRIPTS}/${SETUP_OUDBASE}

# New layer for database runtime
# ----------------------------------------------------------------------
FROM  base

USER  oracle
# copy binaries
COPY  --chown=oracle:oinstall --from=builder $ORACLE_BASE $ORACLE_BASE

# copy oracle inventory
COPY  --chown=oracle:oinstall --from=builder $ORACLE_ROOT/app/oraInventory $ORACLE_ROOT/app/oraInventory

# copy basenv profile stuff
COPY  --chown=oracle:oinstall --from=builder /home/oracle/.OUD_BASE /home/oracle/.bash_profile /home/oracle/

# Finalize image
# ----------------------------------------------------------------------
# expose the OUD ports for ldap, ldaps, http, https, replication, 
# administration and http administration
EXPOSE   ${PORT} ${PORT_SSL} \
         ${PORT_HTTP} ${PORT_HTTPS} \
         ${PORT_ADMIN} ${PORT_ADMIN_HTTP} \
         ${PORT_REP}

# run container health check
HEALTHCHECK    --interval=1m --start-period=5m \
   CMD "${ORADBA_SCRIPTS}/${CHECK_SCRIPT}" >/dev/null || exit 1

# Oracle data volume for OUD instance and configuration files
VOLUME   ["${ORACLE_DATA}"]

# set workding directory
WORKDIR  "${ORACLE_BASE}"

# Define default command to start OUD instance
CMD   exec "${ORADBA_SCRIPTS}/${START_SCRIPT}"
# --- EOF --------------------------------------------------------------