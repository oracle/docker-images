#
# Copyright (c) 2025 Oracle and/or its affiliates. All rights reserved.


#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE HTTP Server DOCKERFILES PROJECT
# -----------------------------------------
# This is the DockerFile for Oracle HTTP Server 14.1.2.0.0
#
# IMPORTANT
# -------------------------------------------
# The resulting image of this Dockerfile would have Oracle Linux 8 and 9 and Oracle HTTP Server 14.1.2.0.0 installed in standalone mode.

# A standalone domain will be configured in this image
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) V1045136-01.zip Oracle HTTP Server 14.1.2.0 for Linux x86-64 installer
#     Download from http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html
#     unzip you will need the OHS installer (bin file) fmw_14.1.2.0.0_ohs_linux64.bin
#
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# As root user run following command manually:
#
#     $ sh buildDockerImage.sh -v 14.1.2.0.0
#
# Alternatively you can also run
# 
#     $ docker build --force-rm=true --no-cache=true --rm=true -t oracle/$IMAGE_NAME:$VERSION-$INSTALL_TYPE .
#
# For example
# 
#     $ docker build --force-rm=true --no-cache=true --rm=true -t oracle/ohs:14.1.2.0.0 .
#
# Pull JDK 17 image from OCR as  base image
# -----------------------------------------
FROM container-registry.oracle.com/java/jdk:17.0.14

# Environment variables required for this build (do NOT change)
# ----------------------------------------------
ENV OHS_PKG=V1045136-01.zip
ENV OHS_BIN=fmw_14.1.2.0.0_ohs_linux64.bin 
ENV ORACLE_HOME=/u01/oracle
ENV NM_PORT=5556 
ENV OHS_LISTEN_PORT=7777 
ENV OHS_SSL_PORT=4443 
ENV JAVA_HOME=/usr/java/default 
ENV DOMAIN_NAME=ohsDomain 
ENV OHS_COMPONENT_NAME=ohs1 
ENV PATH=${PATH}:${ORACLE_HOME}:/usr/java/default/bin:${ORACLE_HOME}/oracle_common/common/bin:${ORACLE_HOME}/user_projects/domains/ohsDomain/bin
ENV WLST_HOME=/u01/oracle/oracle_common/common/bin


# Copy packages to the new drive
# -------------------------------------------------------
COPY ${OHS_PKG} install.file oraInst.loc /u01/

# Install OL 8 or OL 9 required packages. Refer FMW 14.1.2.0.0 System requirements guide for complete list of packages
# Setup filesystem and oracle user
#---------------------------------------------------------------------------------------------------------
RUN yum install -y unzip libaio sysstat make psmisc gcc && \
    yum clean all && \
    chmod a+xr /u01 && \
    useradd -b /u01 -m -s /bin/bash oracle  && \
    mkdir /u01/oracle/.inventory /u01/oracle/bootdir &&  \
    chown oracle:oracle -R /u01

# Go to /u01 as user 'oracle' to proceed with OHS installation
#--------------------------------------------------------
USER oracle
WORKDIR /u01
#RUN unzip -q /u01/${OHS_PKG} && cd - && \
RUN unzip -q /u01/${OHS_PKG} && \
    /u01/${OHS_BIN} -silent -novalidation -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc ORACLE_HOME=${ORACLE_HOME} && \ 
    rm /u01/${OHS_BIN}  /u01/oraInst.loc /u01/install.file && \
    mkdir -p /u01/oracle/logs  && \
    chown oracle:oracle -R /u01/oracle/logs 

# Copy required files to build this image
# ------------------------------------------------------
COPY container-scripts/* /u01/oracle/

#Expose all Ports
EXPOSE ${OHS_SSL_PORT} ${OHS_LISTEN_PORT} ${NM_PORT}

# Final setup
USER oracle
WORKDIR ${ORACLE_HOME} 

# Provision OHS instance
CMD ["/u01/oracle/provisionOHS.sh"]
