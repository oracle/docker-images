# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image built under 12213-doma-home-in-image.
#
# It will deploy any package defined in APP_PKG_FILE.
# into the DOMAIN_HOME with name defined in APP_NAME
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build --build-arg APPLICATION_NAME=sample --build-arg APPLICATION_PKG=archive.zip -t 12213-domain-with-app .
#

# Pull base image
# ---------------
FROM 12213-domain-home-in-image

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

ARG APPLICATION_NAME="${APPLICATION_NAME:-sample}"
ARG APPLICATION_PKG="${APPLICATION_PKG:-archive.zip}"

# Define variables
ENV APP_NAME="${APPLICATION_NAME}" \
    APP_FILE="${APPLICATION_NAME}.war" \
    APP_PKG_FILE="${APPLICATION_PKG}" 

# Copy files and deploy application in WLST Offline mode
COPY container-scripts/* /u01/oracle/
COPY $APP_PKG_FILE /u01/oracle/

RUN cd /u01/oracle & $JAVA_HOME/bin/jar xf /u01/oracle/$APP_PKG_FILE && \
    /u01/oracle/deployAppToDomain.sh
    
# Define default command to start bash.
CMD ["startAdminServer.sh"]
