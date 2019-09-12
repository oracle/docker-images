#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle WebLogic 12.2.1.3 domain persisted on a Docker volume
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# This Oracle WebLogic domain image extends the Oracle WebLogic 12.2.1.3 developer image, you must first build the Oracle WebLogic 12.2.1.3 binary image.
# Run:
#      $ docker build -f Dockerfile -t 12213-weblogic-domain-in-volume .
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a WebLogic Domain.
#
# From
# ----
FROM oracle/weblogic:12.2.1.3-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# WLS Configuration
# -----------------
ENV CUSTOM_DOMAIN_NAME="${CUSTOM_DOMAIN_NAME:-base_domain}" \
    CUSTOM_DOMAIN_ROOT="/u01/oracle/user_projects/domains" \
    CUSTOM_ADMIN_PORT="${CUSTOM_ADMIN_PORT:-7001}" \
    CUSTOM_ADMIN_NAME="${CUSTOM_ADMIN_NAME:-AdminServer}" \
    CUSTOM_ADMIN_HOST="${CUSTOM_ADMIN_HOST:-AdminContainer}" \
    CUSTOM_MANAGED_SERVER_PORT="${CUSTOM_MANAGED_SERVER_PORT:-8001}" \
    CUSTOM_MANAGED_SERVER_NAME_BASE="${CUSTOM_MANAGED_SERVER_NAME_BASE:-MS}" \
    CUSTOM_CONFIGURED_MANAGED_SERVER_COUNT="${CUSTOM_CONFIGURED_MANAGED_SERVER_COUNT:-2}" \
    CUSTOM_MANAGED_NAME="${CUSTOM_MANAGED_NAME:-MS1}" \
    CUSTOM_CLUSTER_NAME="${CUSTOM_CLUSTER_NAME:-cluster1}" \
    CUSTOM_CLUSTER_TYPE="${CUSTOM_CLUSTER_TYPE:-DYNAMIC}" \
    CUSTOM_PRODUCTION_MODE_ENABLED="${CUSTOM_PRODUCTION_MODE_ENABLED:-prod}" \
    PROPERTIES_FILE_DIR="/u01/oracle/properties" \
    CUSTOM_JAVA_OPTIONS="-Doracle.jdbc.fanEnabled=false -Dweblogic.StdoutDebugEnabled=false"  \
    CUSTOM_PATH="$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts"

# Add files required to build this image
COPY --chown=oracle:oracle container-scripts/* /u01/oracle/container-scripts/

#Create directory where domain will be written to
USER root
RUN mkdir -p $CUSTOM_DOMAIN_ROOT && \
    chown -R oracle:oracle $CUSTOM_DOMAIN_ROOT/.. && \
    chmod -R a+xwr $CUSTOM_DOMAIN_ROOT/.. && \
    mkdir -p $ORACLE_HOME/properties && \
    chmod -R a+r $ORACLE_HOME/properties && \ 
    chmod +x /u01/oracle/container-scripts/*

VOLUME $CUSTOM_DOMAIN_ROOT

USER oracle
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/container-scripts/createWLSDomain.sh"]
