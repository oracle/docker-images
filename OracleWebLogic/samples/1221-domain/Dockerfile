# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
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
#      $ sudo docker build -t 1221-domain --build-arg ADMIN_PASSWORD=welcome1 .
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1-developer

# Maintainer
# ----------
MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# WLS Configuration
# ----------------------------------------------------------
ARG ADMIN_PASSWORD
ENV DOMAIN_NAME="base_domain" \
    ADMIN_PORT="8001" \
    ADMIN_HOST="wlsadmin" \
    NM_PORT="5556" \
    MS_PORT="7001" \
    CLUSTER_NAME="DockerCluster" \
    PATH=$PATH:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin:/u01/oracle

# Add files required to build this image
USER oracle
COPY container-scripts/* /u01/oracle/

# Configuration of WLS Domain
RUN /u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/create-wls-domain.py && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security && \
    echo "username=weblogic" > /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \ 
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \ 
    echo "export PATH=$PATH:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin" >> /u01/oracle/.bashrc

# Expose Node Manager default port, and also default for admin and managed server 
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT

# Final setup
WORKDIR /u01/oracle

# Define default command to start bash. 
CMD ["startWebLogic.sh"]
