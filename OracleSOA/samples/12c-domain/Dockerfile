# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# (TODO)
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
#      $ sudo docker build -t mysoa .
#

# Pull base image
# ---------------
FROM oracle/soa:12.1.3-dev

# Maintainer
# ----------
MAINTAINER Jorge Quilcate <quilcate.jorge@gmail.com>

# WLS Configuration
# -------------------------------
ENV JAVA_HOME /usr/java/default
ENV ADMIN_PASSWORD welcome1
ENV ADMIN_PORT 7001
ENV OSB_DEBUG_PORT 7453
ENV SOA_DEBUG_PORT 5004
ENV USER_MEM_ARGS -Xms1024m -Xmx2058m -XX:MaxPermSize=1024m
# ENV DB_HOST dbhost
# ENV DB_PORT 49161
# ENV DB_SERVICE XE

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

# Configuration of SOA Domain
USER oracle
WORKDIR /u01/oracle/soa
RUN /u01/oracle/soa/wlserver/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/create-soa-domain.py 

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE $ADMIN_PORT $OSB_DEBUG_PORT $SOA_DEBUG_PORT

# Final setup
WORKDIR /u01/oracle

ENV PATH $PATH:/u01/oracle/soa/wlserver/common/bin:/u01/oracle/work/domains/soa_domain/bin:/u01/oracle

# Define default command to start bash. 
CMD ["sh", "/u01/oracle/work/domains/soa_domain/startWebLogic.sh"]