
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FMW Infrastructure 12.2.1.3 domain 
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# The Oracle FMW Infrastructure image extends the Oracle WebLogic Infrastructure 12.2.1.3 image, you must first build the Oracle WebLogic Infrastructure image.
# Run:
#      $ docker build -f Dockerfile --network=InfraNET -t 12213-fmw-domain-in-image .
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a FMW Infra Base Domain.
#
# From
# -------------------------
FROM oracle/fmw-infrastructure:12.2.1.3

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

ARG CUSTOM_DOMAIN_NAME="${CUSTOM_DOMAIN_NAME:-infradomain}"
ARG CUSTOM_ADMIN_PORT="${CUSTOM_ADMIN_PORT:-7001}"
ARG CUSTOM_ADMIN_HOST="${CUSTOM_ADMIN_HOST:-InfraAdminContainer}"
ARG CUSTOM_ADMIN_NAME="${CUSTOM_ADMIN_NAME:-AdminServer}"
ARG CUSTOM_MANAGED_BASE_NAME="${CUSTOM_MANAGED_BASE_NAME:-infraServer}" 
ARG CUSTOM_MANAGED_SERVER_COUNT="${CUSTOM_MANAGED_SERVER_COUNT:-2}" 
ARG CUSTOM_MANAGEDSERVER_PORT="${CUSTOM_MANAGEDSERVER_PORT:-8001}"
ARG CUSTOM_CLUSTER_NAME="${CUSTOM_CLUSTER_NAME:-infraCluster}" 
ARG CUSTOM_RCUPREFIX="${CUSTOM_RCUPREFIX:-INFRA01}" 
ARG CUSTOM_PRODUCTION_MODE="${CUSTOM_PRODUCTION_MODE:-prod}" 
ARG CUSTOM_DEBUG_PORT="${CUSTOM_DEBUG_PORT:-8453}" 
ARG CUSTOM_DEBUG_FLAG="${CUSTOM_DEBUG_FLAG:-false}"
ARG CUSTOM_CONNECTION_STRING="${CUSTOM_CONNECTION_STRING:-"InfraDB:1521/InfraPDB1.us.oracle.com"}"

# WLS Configuration
# ---------------------------
ENV ORACLE_HOME="/u01/oracle" \
    PROPERTIES_FILE_DIR="/u01/oracle/properties" \
    DOMAIN_NAME="${CUSTOM_DOMAIN_NAME}" \
    CUSTOM_DOMAIN_ROOT="/u01/oracle/user_projects/domains" \
    DOMAIN_HOME="/u01/oracle/user_projects/domains/${CUSTOM_DOMAIN_NAME}" \
    CUSTOM_ADMIN_PORT="${CUSTOM_ADMIN_PORT}" \
    CUSTOM_ADMIN_NAME="${CUSTOM_ADMIN_NAME}" \
    CUSTOM_ADMIN_HOST="${CUSTOM_ADMIN_HOST}" \
    CUSTOM_MANAGEDSERVER_PORT="${CUSTOM_MANAGEDSERVER_PORT}" \
    CUSTOM_MANAGED_BASE_NAME="${CUSTOM_MANAGED_BASE_NAME}" \
    CUSTOM_MANAGED_NAME="${CUSTOM_MANAGED_NAME}" \
    CUSTOM_MANAGED_SERVER_COUNT="${CUSTOM_MANAGED_SERVER_COUNT}" \
    CUSTOM_CLUSTER_NAME="${CUSTOM_CLUSTER_NAME}" \
    CUSTOM_RCUPREFIX="${CUSTOM_RCUPREFIX}" \
    CUSTOM_CONNECTION_STRING="${CUSTOM_CONNECTION_STRING}" \
    CUSTOM_PRODUCTION_MODE="${CUSTOM_PRODUCTION_MODE}" \
    CUSTOM_DEBUG_PORT="${CUSTOM_DEBUG_PORT}" \
    CUSTOM_DEBUG_FLAG="${CUSTOM_DEBUG_FLAG}" \
    CUSTOM_JAVA_OPTIONS="-Doracle.jdbc.fanEnabled=false -Dweblogic.StdoutDebugEnabled=false" \
    PATH="$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts:${DOMAIN_HOME}/bin"

# Add files required to build this image
COPY container-scripts/* /u01/oracle/container-scripts/

#Create directory where domain will be written to
USER root
RUN chmod +x /u01/oracle/container-scripts/* && \
    mkdir -p +xwr ${PROPERTIES_FILE_DIR} && \
    chown -R oracle:oracle ${PROPERTIES_FILE_DIR} && \
    mkdir -p $DOMAIN_HOME && \
    chown -R oracle:oracle $DOMAIN_HOME/.. && \
    chmod -R a+xwr $DOMAIN_HOME/..

USER oracle
COPY properties/*.properties ${PROPERTIES_FILE_DIR}/

# Configuration of WLS Domain
RUN /u01/oracle/container-scripts/createFMWDomain.sh && \
    echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
    chmod -R a+x $DOMAIN_HOME/bin/*.sh  && \
    rm ${PROPERTIES_FILE_DIR}/*.properties

WORKDIR $DOMAIN_HOME

# Define default command to start bash.
CMD ["startAdminServer.sh"]
