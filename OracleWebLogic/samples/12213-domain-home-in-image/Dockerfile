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

ARG CUSTOM_DOMAIN_NAME="${CUSTOM_DOMAIN_NAME:-base_domain}"

ARG DOM_ADMIN_PORT="${DOM_ADMIN_PORT:-7001}"  
ARG DOM_ADMIN_NAME="${DOM_ADMIN_NAME:-AdminServer}" 
ARG MANAGED_SERVER_NAME_BASE="${MANAGED_SERVER_NAME_BASE:-MS}"
ARG MANAGED_SERVER_PORT="${MANAGED_SERVER_PORT:-8001}"
ARG DOM_CLUSTER_NAME="${DOM_CLUSTER_NAME:-DockerCluster}" 
ARG DOM_DEBUG_FLAG="${DOM_DEBUG_FLAG:-true}" 
ARG PRODUCTION_MODE_ENABLED="${DOM_PRODUCTION_MODE_ENABLED:-false}"
ARG CLUSTER_TYPE="${CLUSTER_TYPE:-DYNAMIC}"
ARG CONFIGURED_MANAGED_SERVER_COUNT="${CONFIGURED_MANAGED_SERVER_COUNT:-2}" 

# WLS Configuration
# ---------------------------
ENV DOMAIN_NAME="${CUSTOM_DOMAIN_NAME}" \
    PRE_DOMAIN_HOME=/u01/oracle/user_projects \
    ADMIN_HOST="wlsadmin" \
    NM_PORT="5556" \
    DEBUG_PORT="8453" \
    ORACLE_HOME=/u01/oracle \
    CONFIG_JVM_ARGS="-Dweblogic.security.SSL.ignoreHostnameVerification=true"  \
    DOMAIN_HOME="/u01/oracle/user_projects/domains/${DOMAIN_NAME}" \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:${DOMAIN_HOME}:${DOMAIN_HOME}/bin:/u01/oracle

# Domain and Server environment variables
# ------------------------------------------------------------
ENV ADMIN_PORT="${DOM_ADMIN_PORT}"  \
    ADMIN_SERVER_NAME="${DOM_ADMIN_NAME}" \
    MANAGED_SERVER_NAME_BASE="${MANAGED_SERVER_NAME_BASE}" \
    MANAGE_S_NAME="${MANAGE_S_NAME}" \
    MANAGED_SERVER_PORT="${MANAGED_SERVER_PORT}" \
    CLUSTER_NAME="${DOM_CLUSTER_NAME}" \
    DEBUG_FLAG="$(DOM_DEBUG_FLAG}" \
    CONFIGURED_MANAGED_SERVER_COUNT="${CONFIGURED_MANAGED_SERVER_COUNT}" \
    PROPERTIES_FILE_DIR="/u01/oracle/properties" \
    PRODUCTION_MODE_ENABLED="${PRODUCTION_MODE_ENABLED}"

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

#Create directory where domain will be written to
USER root
RUN chmod +xw /u01/oracle/*.sh && \
    chmod +xw /u01/oracle/*.py && \
    mkdir +xwr ${PROPERTIES_FILE_DIR} && \
    chown -R oracle:oracle ${PROPERTIES_FILE_DIR} && \
    mkdir -p $DOMAIN_HOME && \
    chown -R oracle:oracle $DOMAIN_HOME && \
    chmod -R a+xwr $DOMAIN_HOME

COPY properties/domain.properties ${PROPERTIES_FILE_DIR}
# Configuration of WLS Domain
RUN /u01/oracle/createWLSDomain.sh && \
    echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
    chmod -R a+x $DOMAIN_HOME/bin/*.sh  && \
    rm ${PROPERTIES_FILE_DIR}/domain.properties

# Expose Node Manager default port, and also default for admin and managed server
EXPOSE $ADMIN_PORT $MANAGED_SERVER_PORT $DEBUG_PORT

WORKDIR $DOMAIN_HOME

# Define default command to start bash.
CMD ["startAdminServer.sh"]
