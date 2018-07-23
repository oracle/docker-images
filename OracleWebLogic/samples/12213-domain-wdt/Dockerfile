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
# Build the deployment archive file using the build-archive.sh script.
#      $ ./build-archive.sh
#
# Run:
#      $ sudo docker build \
#            --build-arg WDT_MODEL=simple-topology.yaml \
#            --build-arg WDT_ARCHIVE=archive.zip \
#            --force-rm=true \
#            -t 12213-domain-wdt .
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.3-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

ARG WDT_MODEL
ARG WDT_ARCHIVE

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
    PRE_DOMAIN_HOME=/u01/oracle/user_projects \
    ADMIN_PORT="${ADMIN_PORT:-7001}" \
    WDT_MODEL="$WDT_MODEL" \
    WDT_ARCHIVE="$WDT_ARCHIVE"

# Add files required to build this image
COPY container-scripts/* /u01/oracle/
COPY ${WDT_MODEL} ${ARCHIVE_FILE} /u01/


# this file contains credentials.
# be sure to build with --force-rm to eliminate this container layer
COPY properties /u01/oracle

# Create directory where domain will be written to
USER root
RUN chmod +xw /u01/oracle/*.sh && \
    chmod +xw /u01/oracle/*.py && \
    mkdir -p $PRE_DOMAIN_HOME && \
    mkdir -p $PRE_DOMAIN_HOME/domains && \
    chmod a+xr $PRE_DOMAIN_HOME && \
    chown -R oracle:oracle $PRE_DOMAIN_HOME && \
    cd /u01 && \
    curl -OL https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.11/weblogic-deploy.zip && \
    $JAVA_HOME/bin/jar xf /u01/weblogic-deploy.zip && \
    chmod +xw /u01/weblogic-deploy/bin/*.sh && \
    chmod -R +xw /u01/weblogic-deploy/lib/python && \
    if [ -n "$WDT_MODEL" ]; then MODEL_OPT="-model_file /u01/$WDT_MODEL"; fi && \
    if [ -n "$WDT_ARCHIVE" ]; then ARCHIVE_OPT="-archive_file /u01/$WDT_ARCHIVE"; fi && \
    /u01/weblogic-deploy/bin/createDomain.sh \
        -oracle_home $ORACLE_HOME \
        -java_home ${JAVA_HOME} \
        -domain_parent $PRE_DOMAIN_HOME/domains \
        -domain_type WLS \
        -variable_file /u01/oracle/domain.properties \
        $MODEL_OPT \
        $ARCHIVE_OPT && \
    chown -R oracle:oracle $PRE_DOMAIN_HOME && \
    rm /u01/oracle/domain.properties

VOLUME $PRE_DOMAIN_HOME
# Expose Node Manager default port, and also default for admin and managed server
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT $DEBUG_PORT

USER oracle
WORKDIR $ORACLE_HOME

# Define default command to start bash.
CMD ["/u01/oracle/startWLSDomain.sh"]
