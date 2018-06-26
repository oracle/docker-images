# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.19
# Revision...: 1.0
# Purpose....: This Dockerfile is to build Oracle Unifid Directory
# Notes......: --
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as
#              shown at http://oss.oracle.com/licenses/upl.
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ----------------------------------------------------------------------

# Pull base image
# ----------------------------------------------------------------------
FROM oracle/serverjre:8

# Maintainer
# ----------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@trivadis.com"

# Arguments for Oracle Installation
ARG ORACLE_ROOT
ARG ORACLE_DATA
ARG ORACLE_BASE
ARG ORAREPO

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORAREPO=${ORAREPO:-orarepo} \
    DOWNLOAD="/tmp/download" \
    DOCKER_SCRIPTS="/opt/docker/bin" \
    START_SCRIPT="start_oud_instance.sh" \
    CHECK_SCRIPT="check_oud_instance.sh" \
    INSTALL_SCRIPT="setup_oud.sh" \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    ORACLE_HOME_NAME="fmw12.2.1.3.0" \
    ORACLE_ROOT=${ORACLE_ROOT:-/u00} \
    ORACLE_DATA=${ORACLE_DATA:-/u01} \
    OUD_INSTANCE=${OUD_INSTANCE:-oud_docker} \
    PORT="${PORT:-1389}" \
    PORT_SSL="${PORT_SSL:-1636}" \
    PORT_REP="${PORT_REP:-8989}" \
    PORT_ADMIN="${PORT_ADMIN:-4444}" \
    FMW_OUD_PKG="p26270957_122130_Generic.zip"

# Use second ENV so that variable get substituted
ENV ORACLE_BASE=${ORACLE_BASE:-$ORACLE_ROOT/app/oracle} \
    OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-$ORACLE_DATA/instances} \
    OUD_INSTANCE_HOME=${OUD_INSTANCE_HOME:-$ORACLE_DATA/instances/$OUD_INSTANCE} \
    OUD_INSTANCE_ADMIN=${OUD_INSTANCE_ADMIN:-$ORACLE_DATA/admin/$OUD_INSTANCE}

# same same but different...
# third ENV so that variable get substituted
ENV PATH=${PATH}:"${OUD_INSTANCE_HOME}/OUD/bin:${ORACLE_BASE}/product/${ORACLE_HOME_NAME}/oud/bin:${DOCKER_SCRIPTS}" \
    ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_HOME_NAME}

# RUN as user root
# ----------------------------------------------------------------------
# - create group oracle and oinstall
# - create user oracle
# - setup subdirectory to install OUDpackage and container-scripts
# - create softlink for the OUD setup scripts
# - adjust owner ship of download folder
# -----------------------------------------------------------------
RUN groupadd --gid 1000 oracle && \
    groupadd --gid 1010 oinstall && \
    useradd --create-home --gid oracle --groups oracle,oinstall \
        --shell /bin/bash oracle && \
    install --owner oracle --group oracle --mode=775 --verbose --directory \
        ${ORACLE_ROOT} \
        ${ORACLE_BASE} \
        ${ORACLE_DATA} \
        ${DOWNLOAD} \
        ${DOCKER_SCRIPTS} && \
    ln -s ${ORACLE_DATA}/scripts /docker-entrypoint-initdb.d && \
    chown oracle:oinstall ${DOWNLOAD}

# Fallback if the base image does not provide libaio, tar and gzip
# This yum command will only be executed, if one of the file is not
# available. Otherwise it will just create the *.lang file and remove the
# yum cache which is anyway not there.
# -----------------------------------------------------------------
RUN echo "%_install_langs   en" >/etc/rpm/macros.lang && \
    [ -f /usr/bin/tar -a -f /usr/bin/gzip -a -f /lib64/libaio.so.? ] || \
    yum install -y libaio gzip tar && \
    rm -rf /var/cache/yum

# Copy scripts and software
# ----------------------------------------------------------------------
# copy all setup scripts to DOCKER_BIN
COPY scripts/* "${DOCKER_SCRIPTS}/"

# COPY oud/software and response files
COPY *zip* install.rsp oraInst.loc "${DOWNLOAD}/"

# RUN as oracle
# Switch to user oracle, oracle software as to be installed with regular user
# ----------------------------------------------------------------------
USER oracle
RUN "${DOCKER_SCRIPTS}/${INSTALL_SCRIPT}" ${FMW_OUD_PKG}

# get the latest OUD base from GitHub and install it
RUN "${DOCKER_SCRIPTS}/setup_oudbase.sh"

# Finalize image
# ----------------------------------------------------------------------
# expose the OUD admin, replication and ldap ports
EXPOSE ${PORT} ${PORT_SSL} ${PORT_REP} ${PORT_ADMIN}

# run container health check
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "${DOCKER_SCRIPTS}/${CHECK_SCRIPT}" >/dev/null || exit 1

# Oracle data volume for OUD instance and configuration files
VOLUME ["${ORACLE_DATA}"]

# set workding directory
WORKDIR "${ORACLE_BASE}"

# Define default command to start OUD instance
CMD exec "${DOCKER_SCRIPTS}/${START_SCRIPT}"
# --- EOF --------------------------------------------------------------
