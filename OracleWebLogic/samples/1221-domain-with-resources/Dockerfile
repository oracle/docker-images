# LICENSE UPL 1.0
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic sample 1221-domain
#
# It will create a DataSource as per container-scripts/datasource.properties
# It will create a JMS Server and Queue
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -t 1221-domain-with-resources .
#

# Pull base image
# ---------------
FROM 1221-domain

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Copy files and deploy application in WLST Offline mode
COPY container-scripts/* /u01/oracle/

RUN wlst -loadProperties /u01/oracle/datasource.properties /u01/oracle/ds-deploy.py && \
    wlst /u01/oracle/jms-deploy.py
