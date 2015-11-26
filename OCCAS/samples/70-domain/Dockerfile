# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the OCCAS image by creating a simple domain.
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
FROM oracle/occas:7.0

# Maintainer
# ----------
MAINTAINER Antón R. Yuste <ayuste@optaresolutions.com>

# WLS Configuration
# -------------------------------
ENV ADMIN_PASSWORD welcome1
ENV ADMIN_PORT 8001
ENV NM_PORT 5556
ENV MS_PORT 7001
ENV SIP_PORT 5060
ENV SIPS_PORT 5061
ENV USER_MEM_ARGS -Xms256m -Xmx512m -XX:MaxPermSize=2048m

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

# Root commands
USER root
RUN echo ". /u01/oracle/occas/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /root/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/occas/wlserver/common/bin:/u01/oracle/occas/user_projects/domains/base_domain/bin" >> /root/.bashrc

# Change root password
RUN echo -e "welcome1\nwelcome1" | (passwd --stdin root)

# Configuration of WLS Domain
USER oracle
WORKDIR /u01/oracle/occas
RUN /u01/oracle/occas/wlserver/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/create-wls-domain.py && \
    mkdir -p /u01/oracle/occas/user_projects/domains/base_domain/servers/AdminServer/security && \
    mv /u01/oracle/commEnv.sh /u01/oracle/occas/wlserver/common/bin/commEnv.sh && \
    echo "username=weblogic" > /u01/oracle/occas/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/occas/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/occas/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/occas/wlserver/common/bin:/u01/oracle/occas/user_projects/domains/base_domain/bin" >> /u01/oracle/.bashrc && \
    rm /u01/oracle/create-wls-domain.py /u01/oracle/jaxrs2-template.jar 

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT

# Final setup
WORKDIR /u01/oracle

ENV PATH $PATH:/u01/oracle/occas/wlserver/common/bin:/u01/oracle/occas/user_projects/domains/base_domain/bin:/u01/oracle

# Some problems with OCCAS APP_Router and IPv6

ENV JAVA_OPTIONS $JAVA_OPTIONS -Djava.net.preferIPv4Stack=true

# Define default command to start bash. 
CMD ["startWebLogic.sh"]
