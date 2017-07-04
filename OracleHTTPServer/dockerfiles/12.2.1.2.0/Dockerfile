# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE HTTP Server DOCKERFILES PROJECT
# -----------------------------------------
# This is the DockerFile for Oracle HTTP Server 12.2.1.2.0
#
# IMPORTANT
# -------------------------------------------
# The resulting image of this Dockerfile would have Oracle Linux 7.3 and Oracle HTTP Server 12.2.1.2.0 installed in standalone mode.
# A standalone domain will be configured in this image
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.0_ohs_linux64_Disk1_1of1.zip
#     Download from http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# As root user run following command manually:
#
#     $ sh buildDockerImage.sh -v 12.2.1.2.0
#
# Alternatively you can also run
# 
#     $ docker build --force-rm=true --no-cache=true --rm=true -t oracle/$IMAGE_NAME:$VERSION-$INSTALL_TYPE .
#
# For example
# 
#     $ docker build --force-rm=true --no-cache=true --rm=true -t oracle/ohs:12.2.1.2.0-sa .
#
# Pull serverjre:8 base image
# -----------------------------------
FROM oracle/serverjre:8

# Maintainer
# ------------------------------------
MAINTAINER Prabhat Kishore <prabhat.kishore@oracle.com>

# Environment variables required for this build (do NOT change)
# ----------------------------------------------
ENV OHS_PKG=fmw_12.2.1.2.0_ohs_linux64_Disk1_1of1.zip \
    OHS_BIN=fmw_12.2.1.2.0_ohs_linux64.bin \
    ORACLE_HOME=/u01/oracle/ohssa \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \ 
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/ohssa/oracle_common/common/bin \
    NM_PORT=5556 \
    OHS_LISTEN_PORT=7777 \
    OHS_SSL_PORT=4443 \
    JAVA_HOME=/usr/java/default \
    MW_HOME=/u01/oracle/ohssa \
    DOMAIN_NAME=ohsDomain \
    OHS_COMPONENT_NAME=ohs_sa1 \
    PATH=$PATH:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/user_projects/domains/ohsDomain/bin:/u01/oracle/container-scripts


# Copy packages to the new drive
# -------------------------------------------------------
COPY $OHS_PKG install.file oraInst.loc /u01/

# Install OL7 required packages. Refer FMW 12.2.1.2 System requirements guide for complete list of packages
# Change the open file limits and kernel parameters that need changing
# Setup filesystem and oracle user
#---------------------------------------------------------------------------------------------------------
# Proxy needs to be set before running yum in /etc/yum.conf
RUN yum install -y \
        unzip libaio sysstat && \
    yum clean all && \
    chmod a+xr /u01 && \
    useradd -b /u01 -m -s /bin/bash oracle && \
    mkdir /u01/oracle/.inventory && \
    chown oracle:oracle -R /u01 

# Install and configure Oracle JDK
# Go to /u01 as user 'oracle' to proceed with OHS installation
#--------------------------------------------------------
USER oracle
RUN cd /u01 && unzip -q /u01/$OHS_PKG && cd - && \
    /u01/$OHS_BIN -ignoreSysPrereqs -novalidation -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc ORACLE_HOME=$ORACLE_HOME && \ 
    rm /u01/$OHS_BIN /u01/$OHS_PKG /u01/oraInst.loc /u01/install.file && \
    mkdir /u01/oracle/container-scripts/ /u01/oracle/logs 

# Copy required files to build this image
# ------------------------------------------------------
COPY container-scripts/* /u01/oracle/container-scripts/

#Expose all Ports
EXPOSE $OHS_SSL_PORT $OHS_LISTEN_PORT $NM_PORT

# Final setup
WORKDIR /u01/oracle/container-scripts

# Create Doamin, OHS instance and start the  OHS instance
RUN sh createDomain.sh 

# Define default command to start bash
CMD ["startNMandOHS.sh"]

