#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain.
#
# Util scripts are copied into the image enabling users to plug NodeManager
# automatically into the AdminServer running on another container.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t 12213-domain-home-image
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.3-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

ARG CUSTOM_DOMAIN_NAME="${CUSTOM_DOMAIN_NAME:-domain1}"
ARG CUSTOM_ADMIN_SERVER_PORT="${CUSTOM_ADMIN_SERVER_PORT:-7001}"  
ARG CUSTOM_MANAGED_SERVER_PORT="${CUSTOM_MANAGED_SERVER_PORT:-8001}"
ARG CUSTOM_DEBUG_PORT="${CUSTOM_DEBUG_PORT:-8453}"
ARG CUSTOM_ADMIN_SERVER_NAME="${CUSTOM_ADMIN_SERVER_NAME:-admin-server}"
ARG CUSTOM_ADMIN_HOST="${CUSTOM_ADMIN_HOST:-wlsadmin}"
ARG CUSTOM_CLUSTER_NAME="${CUSTOM_CLUSTER_NAME:-DockerCluster}"
ARG CUSTOM_SSL_ENABLED="${SSL_ENABLED:-false}"
ARG CUSTOM_ADMIN_SERVER_SSL_PORT="${CUSTOM_ADMIN_SERVER_SSL_PORT}"

# WLS Configuration
# ---------------------------
ENV ORACLE_HOME=/u01/oracle \
    PROPERTIES_FILE_DIR="/u01/oracle/properties" \
    SSL_ENABLED="${CUSTOM_SSL_ENABLED}" \
    DOMAIN_NAME="${CUSTOM_DOMAIN_NAME}" \
    DOMAIN_HOME="/u01/oracle/user_projects/domains/${CUSTOM_DOMAIN_NAME}" \
    ADMIN_SERVER_PORT="${CUSTOM_ADMIN_SERVER_PORT}" \
    ADMIN_SERVER_SSL_PORT="${CUSTOM_ADMIN_SERVER_SSL_PORT}" \
    ADMIN_SERVER_NAME="${CUSTOM_ADMIN_SERVER_NAME}" \
    ADMIN_HOST="${CUSTOM_ADMIN_HOST}" \
    CLUSTER_NAME="${CUSTOM_CLUSTER_NAME}" \
    MANAGED_SERVER_PORT="${CUSTOM_MANAGED_SERVER_PORT}" \
    MANAGED_SERVER_NAME="${CUSTOM_MANAGED_SERVER_NAME}" \
    DEBUG_PORT="8453" \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:${DOMAIN_HOME}:${DOMAIN_HOME}/bin:/u01/oracle

# Add files required to build this image
COPY --chown=oracle:oracle container-scripts/* /u01/oracle/

#Create directory where domain will be written to
USER root
RUN chmod +xw /u01/oracle/*.sh && \
    chmod +xw /u01/oracle/*.py && \
    mkdir -p ${PROPERTIES_FILE_DIR} && \
    chown -R oracle:oracle ${PROPERTIES_FILE_DIR} && \
    mkdir -p $DOMAIN_HOME && \
    chown -R oracle:oracle $DOMAIN_HOME/.. && \
    chmod -R a+xwr $DOMAIN_HOME/..

COPY --chown=oracle:oracle properties/docker-build/domain*.properties ${PROPERTIES_FILE_DIR}/

# Configuration of WLS Domain
USER oracle
RUN /u01/oracle/createWLSDomain.sh && \
    echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
    chmod -R a+x $DOMAIN_HOME/bin/*.sh  && \
    rm ${PROPERTIES_FILE_DIR}/*.properties

# Expose ports for admin, managed server, and debug
EXPOSE $ADMIN_SERVER_PORT $MANAGED_SERVER_PORT $DEBUG_PORT

WORKDIR $DOMAIN_HOME

# Define default command to start bash.
CMD ["startAdminServer.sh"]
