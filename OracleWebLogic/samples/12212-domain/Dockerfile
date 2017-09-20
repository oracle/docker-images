#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
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
#      $ sudo docker build -t 12212-domain
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.2-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# WLS Configuration 
# ---------------------------
ENV ADMIN_HOST="wlsadmin" \
    NM_PORT="5556" \
    MS_PORT="8001" \
    DEBUG_PORT="8453" \
    ORACLE_HOME=/u01/oracle \
    SCRIPT_FILE=/u01/oracle/createAndStartWLSDomain.sh \
    CONFIG_JVM_ARGS="-Dweblogic.security.SSL.ignoreHostnameVerification=true"  \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/${DOMAIN_NAME:-base_domain}/bin:/u01/oracle

# Domain and Server environment variables
# ------------------------------------------------------------
ENV DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    PRE_DOMAIN_HOME=/u01/oracle/user_projects/domains \
    ADMIN_PORT="${ADMIN_PORT:-7001}"  \
    ADMIN_USERNAME="${ADMIN_USERNAME:-weblogic}" \
    ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-""}" \
    CLUSTER_NAME="${CLUSTER_NAME:-DockerCluster}" \
    DEBUG_FLAG=true \
    PRODUCTION_MODE=dev 

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

#Create directory where domain will be written to
RUN mkdir -p $PRE_DOMAIN_HOME && \ 
    chmod a+xr $PRE_DOMAIN_HOME && \
    chown oracle:oracle -R $PRE_DOMAIN_HOME

# Expose Node Manager default port, and also default for admin and managed server 
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT $DEBUG_PORT

USER oracle
WORKDIR $ORACLE_HOME

# Define default command to start bash. 
CMD ["/u01/oracle/createAndStartWLSDomain.sh"]
