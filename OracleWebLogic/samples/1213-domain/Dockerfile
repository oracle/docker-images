# LICENSE UPL 1.0
#
# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain.
#
# The 'base-domain' created here has Java EE 7 APIs enabled by default:
#  - JAX-RS 2.0 shared lib deployed
#  - JPA 2.1,
#  - WebSockets and JSON-P
#
# Util scripts are copied into the image enabling users to plug NodeManager
# magically into the AdminServer running on another container as a Machine.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t 1213-domain --build-arg ADMIN_PASSWORD=welcome1 .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.1.3-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# WLS Configuration
# -------------------------------
ARG ADMIN_PASSWORD
ARG PRODUCTION_MODE

ENV DOMAIN_NAME="base_domain" \
    PRE_DOMAIN_HOME=/u01/oracle/user_projects \
    ADMIN_PORT="7001" \
    ADMIN_HOST="wlsadmin" \
    NM_PORT="5556" \
    MS_PORT="7002" \
    CONFIG_JVM_ARGS="-Dweblogic.security.SSL.ignoreHostnameVerification=true" \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:$PRE_DOMAIN_HOME/domains/base_domain:$PRE_DOMAIN_HOME/domains/base_domain/bin:/u01/oracle

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

# Configuration of WLS Domain
USER root
WORKDIR /u01/oracle
RUN /u01/oracle/wlst /u01/oracle/create-wls-domain.py && \
    mkdir -p $PRE_DOMAIN_HOME && \
    chmod a+xr $PRE_DOMAIN_HOME && \
    chown -R oracle:oracle $PRE_DOMAIN_HOME && \
    mkdir -p $PRE_DOMAIN_HOME/domains/base_domain/servers/AdminServer/security && \
    echo "username=weblogic" > $PRE_DOMAIN_HOME/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo "password=$ADMIN_PASSWORD" >> $PRE_DOMAIN_HOME/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". $PRE_DOMAIN_HOME/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/wlserver/common/bin:$PRE_DOMAIN_HOME/domains/base_domain/bin" >> /u01/oracle/.bashrc && \
    cp /u01/oracle/commEnv.sh /u01/oracle/wlserver/common/bin/commEnv.sh && \
    rm /u01/oracle/create-wls-domain.py /u01/oracle/jaxrs2-template.jar

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT

USER oracle
WORKDIR $PRE_DOMAIN_HOME/domains/base_domain

# Define default command to start bash.
CMD ["/u01/oracle/user_projects/domains/base_domain/startWebLogic.sh"]
