# LICENSE UPL 1.0
#
# Copyright (c) 2017 CERN
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the ords.war file in the same directory as this Dockerfile. You can download it from here: http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html
# Run: 
#      $ docker build -t 1221-domain-ords-autodeploy --build-arg ADMIN_PASSWORD=welcome1 .
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1-developer

# Maintainer
# ----------
MAINTAINER Luis Rodriguez Fernandez <luis.rodriguez.fernandez@cern.ch>

# WLS Configuration (editable during build time)
# ------------------------------
ARG ADMIN_PASSWORD
ARG ADMIN_NAME
ARG DOMAIN_NAME
ARG ADMIN_PORT
ARG DEBUG_FLAG
ARG PRODUCTION_MODE

# WLS Configuration (editable during runtime)
# ---------------------------
ENV ADMIN_HOST="wlsadmin" \
    DEBUG_PORT="8453"

# WLS Configuration (persisted. do not change during runtime)
# -----------------------------------------------------------
ENV DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-base_domain} \
    ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
    ADMIN_PORT="${ADMIN_PORT:-7001}" \
    debugFlag="${DEBUG_FLAG:-false}" \
    PRODUCTION_MODE="${PRODUCTION_MODE:-dev}" \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/${DOMAIN_NAME:-base_domain}/bin:/u01/oracle

# Add files required to build the image
COPY container-scripts/wlst /u01/oracle/
COPY container-scripts/create-wls-domain.py /u01/oracle/

# Configuration of WLS Domain and ords
RUN /u01/oracle/wlst /u01/oracle/create-wls-domain.py && \
    mkdir -p /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security && \
    echo "username=weblogic" > /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties && \
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/user_projects/domains/$DOMAIN_NAME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc 

# Expose Node Manager default port, and also default for admin and managed server 
EXPOSE $ADMIN_PORT $DEBUG_PORT

# ORDS Configuration (persisted. do not change during runtime)
# ------------------------------------------------------------
ENV ORDS_HOME="/u01/oracle/user_projects/ords"

# Copy the startup file
RUN mkdir $ORDS_HOME && \
    mkdir $ORDS_HOME/conf && \
    mkdir $ORDS_HOME/params

COPY container-scripts/configureORDSandStartWLSDomain.sh $ORDS_HOME

# Add the ords.war to the ORDS_HOME.
COPY ords.war $ORDS_HOME/

# Add the ords_params.properties and set the db parameters
ADD ords_params.properties $ORDS_HOME/params

# Ugly workaround...
USER root
RUN chmod ug+x $ORDS_HOME/*.sh && \
    chown -R oracle:oracle $ORDS_HOME

# Finalize setup
# -------------------
USER oracle

# Define default command to start bash.
CMD $ORDS_HOME/configureORDSandStartWLSDomain.sh
