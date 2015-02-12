# LICENSE CDDL 1.0 + GPL 2.0
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
#      $ sudo docker build -t myweblogic .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.1.3-dev

# Maintainer
# ----------
MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# WLS Admin Password (change it!)
# -------------------------------
ENV ADMIN_PASSWORD welcome1

# WLS Ports
# ----------------------------------------------------------
ENV ADMIN_PORT 7001
ENV ADMIN_PORT_SSL 7002
ENV NM_PORT 5556

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

# Root commands
USER root
RUN echo ". /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /root/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin" >> /root/.bashrc

# Configuration of WLS Domain
USER oracle
WORKDIR /u01/oracle/weblogic
RUN /u01/oracle/weblogic/wlserver/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/create-wls-domain.py && \
    mkdir -p /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security && \
    mv /u01/oracle/commEnv.sh /u01/oracle/weblogic/wlserver/common/bin/commEnv.sh && \
    echo "username=weblogic" > /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \ 
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \ 
    echo "export PATH=$PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin" >> /u01/oracle/.bashrc && \
    rm /u01/oracle/create-wls-domain.py /u01/oracle/jaxrs2-template.jar 

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE $NM_PORT $ADMIN_PORT $ADMIN_PORT_SSL

# Final setup
WORKDIR /u01/oracle

ENV PATH $PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin:/u01/oracle

# Define default command to start bash. 
CMD ["startWebLogic.sh"]
