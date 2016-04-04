# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle HTTP Server install image and configures OHS domain and adds OHS component server
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
#     $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 .
#
# Pull base image
# ---------------
FROM oracle/ohs:12.2.1-sa

# Maintainer
# ----------
MAINTAINER Hemastuti Baruah <hemastuti.baruah@oracle.com>

# Node Manager Password (Change it !)
# Setup environment variables
# ----------------------------------------------------------
ARG NM_PASSWORD
ENV NM_PORT=5556 \
    OHS_LISTEN_PORT=7777 \
    OHS_SSL_PORT=3333 \
    JAVA_HOME=/usr/java/default \
    MW_HOME=/u01/oracle/ohssa \
    ORACLE_HOME=/u01/oracle/ohssa \
    DOMAIN_NAME=ohsDomain \
    OHS_COMPONENT_NAME=ohs_sa1 \
    PATH=$PATH:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/user_projects/domains/ohsDomain/bin:/u01/oracle/container-scripts

# Create necessary dir structure and change owner to oracle user
# -----------------------------------------------------------------
RUN mkdir /u01/oracle/container-scripts/ /u01/oracle/logs && \
    chown -R oracle:oracle /u01/oracle/*

# Copy required files to build this image
# ------------------------------------------------------
USER oracle
COPY container-scripts/* /u01/oracle/container-scripts/

# Configuration of OHS domain
# Copy static html for sanity check
#---------------------------------------------------
RUN $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/create-sa-ohs-domain.py && \
    mv /u01/oracle/container-scripts/commEnv.sh $ORACLE_HOME/oracle_common/common/bin/commEnv.sh && \
    echo ". $ORACLE_HOME/oracle_common/common/bin/commEnv.sh" >> /u01/oracle/.bashrc && \
    echo "export PATH=$PATH:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/user_projects/domains/ohsDomain/bin" >> /u01/oracle/.bashrc && \
    mv /u01/oracle/container-scripts/helloWorld.html $ORACLE_HOME/user_projects/domains/ohsDomain/config/fmwconfig/components/OHS/ohs_sa1/htdocs/helloWorld.html

#Expose all Ports
EXPOSE $OHS_SSL_PORT $OHS_LISTEN_PORT $NM_PORT

# Final setup
USER oracle
WORKDIR /u01/oracle/container-scripts

# Define default command to start bash
CMD ["startNMandOHS.sh"]
