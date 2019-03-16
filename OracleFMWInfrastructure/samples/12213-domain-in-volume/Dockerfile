#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FMW Infrastructure 12.2.1.3
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# The Oracle FMW Infrastructure image extends the Oracle WebLogic Infrastructure 12.2.1.3 image, you must first build the Oracle WebLogic Infrastructure image.
# Run:
#      $ docker build -f Dockerfile -t 12213-fmw-domain-in-volume .
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


# WLS Configuration
# ---------------------------
ENV ORACLE_HOME="/u01/oracle" \
    DOMAIN_NAME="${CUSTOM_DOMAIN_NAME:-infradomain}" \
    CUSTOM_DOMAIN_ROOT="/u01/oracle/user-projects/domains" \
    CUSTOM_DOMAIN_HOME="/u01/oracle/user_projects/domains/${DOMAIN_NAME}" \
    CUSTOM_ADMIN_LISTEN_PORT="${CUSTOM_ADMIN_LISTEN_PORT:-7001}" \
    CUSTOM_ADMIN_NAME="${CUSTOM_ADMIN_NAME:-AdminServer}" \
    CUSTOM_ADMIN_HOST="${CUSTOM_ADMIN_HOST:-InfraAdminContainer}" \
    CUSTOM_MANAGEDSERVER_PORT="${CUSTOM_MANAGEDSERVER_PORT:-8001}" \
    CUSTOM_MANAGED_BASE_NAME="${CUSTOM_MANAGED_BASE_NAME:-infraServer}" \
    CUSTOM_MANAGED_NAME="${CUSTOM_MANAGED_NAME:-infraMS1}" \
    CUSTOM_MANAGED_SERVER_COUNT="${CUSTOM_MANAGED_SERVER_COUNT:-2}" \
    CUSTOM_CLUSTER_NAME="${CUSTOM_CLUSTER_NAME:-infraCluster}" \
    CUSTOM_RCUPREFIX="${CUSTOM_RCUPREFIX:-INFRA01}" \
    CUSTOM_PRODUCTION_MODE="${CUSTOM_PRODUCTION_MODE:-prod}" \
    CUSTOM_DEBUG_PORT="${CUSTOM_DEBUG_PORT:-8453}" \
    CUSTOM_DEBUG_FLAG="${CUSTOM_DEBUG_FLAG:-false}" \
    CUSTOM_JAVA_OPTIONS="-Dweblogic.StdoutDebugEnabled=false" \
    CUSTOM_CONNECTION_STRING="InfraDB:1521/InfraPDB1.us.oracle.com" \
    CUSTOM_PATH="$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts"


# Add files required to build this image
COPY container-scripts/* /u01/oracle/container-scripts/

#Create directory where domain will be written to
USER root
RUN mkdir -p $CUSTOM_DOMAIN_ROOT && \
    chown -R oracle:oracle $CUSTOM_DOMAIN_ROOT && \
    chmod -R a+xwr $CUSTOM_DOMAIN_ROOT && \
    mkdir -p $CUSTOM_DOMAIN_HOME && \
    chmod -R a+xwr $CUSTOM_DOMAIN_HOME && \
    chmod +x /u01/oracle/container-scripts/*

VOLUME  $CUSTOM_DOMAIN_ROOT

USER oracle
WORKDIR $CUSTOM_DOMAIN_HOME
CMD ["/u01/oracle/container-scripts/createFMWDomain.sh"]
