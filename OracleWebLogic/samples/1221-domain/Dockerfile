# LICENSE CDDL 1.0 + GPL 2.0
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
#      $ sudo docker build -t 1221-domain .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1-dev

# Maintainer
# ----------
MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# WLS Admin Password (change it!)
# -------------------------------
ENV ADMIN_PASSWORD welcome1

# WLS Configuration
# ----------------------------------------------------------
ENV ADMIN_PORT 8001
ENV NM_PORT 5556
ENV MS_PORT 7001 
ENV CLUSTER_NAME "Cluster-Docker"

# Add files required to build this image
USER oracle
COPY container-scripts/* /u01/oracle/

# Root commands
USER root
RUN chown oracle:oracle /u01/oracle/* && \
    echo ". /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /root/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin" >> /root/.bashrc

# Configuration of WLS Domain
USER oracle
WORKDIR /u01/oracle/weblogic
RUN /u01/oracle/weblogic/wlserver/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/create-wls-domain.py && \
    mkdir -p /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security && \
    echo "username=weblogic" > /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \ 
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \ 
    echo "export PATH=$PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin" >> /u01/oracle/.bashrc

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT

# Final setup
WORKDIR /u01/oracle

ENV PATH $PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin:/u01/oracle

# Define default command to start bash. 
CMD ["startWebLogic.sh"]
