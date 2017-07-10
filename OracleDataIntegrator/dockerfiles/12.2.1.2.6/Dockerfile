# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Data Integrator 12.2.1.2.6
#
# Base image of this dockerfile is Oracle Java 8 docker image.
#
# Pre-requisite to build oracle Oracle Data Integrator 12.2.1.2.6 image is to have
# Oracle Java 8 docker image
#
# To build Oracle Java 8 docker image, kindly refer below link
# https://github.com/oracle/docker-images/tree/master/OracleJava
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.6_odi_Disk1_1of2.zip
# (2) fmw_12.2.1.2.6_odi_Disk1_2of2.zip
#   Download the production distribution for Oracle Data Integrator from the Oracle Software Delivery Cloud
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Make sure that Oracle Java 8 image is available
# Run:
#      $ docker build -t oracle/odi:12.2.1.2.6 .
#
#
# Pull base image
# ---------------
FROM oracle/serverjre:8

#
# Maintainer
# ----------
MAINTAINER Manish Vaishnani <manish.vaishnani@oracle.com>

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ODI_PKG1=fmw_12.2.1.2.6_odi_Disk1_1of2.zip \
    ODI_PKG2=fmw_12.2.1.2.6_odi_Disk1_2of2.zip \
    ODI_JAR=fmw_12.2.1.2.6_odi.jar \
    ODI_JAR2=fmw_12.2.1.2.6_odi2.jar \
    ORACLE_HOME=/u01/oracle \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/container-scripts \
    ODI_AGENT_PORT=20910 \
    DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}"

#
# Proxy needs to be set before running yum 
# ----------------------------------------
RUN mkdir /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    mkdir -p /u01/oracle/container-scripts /u01/oracle/logs && \
    chmod a+xr /u01 

#
# Copy required files to build this image
# ---------------------------------------
COPY $ODI_PKG1 $ODI_PKG2 oraInst.loc /u01/
COPY container-scripts/* /u01/oracle/container-scripts/

RUN chown oracle:oracle -R /u01 && \
    chmod a+xr /u01/oracle/container-scripts/*.*

#
# Install as oracle user
# ----------------------
USER oracle
RUN cd /u01 && \
    $JAVA_HOME/bin/jar xf /u01/$ODI_PKG1  && \
    $JAVA_HOME/bin/jar xf /u01/$ODI_PKG2  && \
    $JAVA_HOME/bin/java -jar /u01/$ODI_JAR -silent -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Standalone Installation" && \
     rm /u01/$ODI_PKG1 /u01/$ODI_PKG2 /u01/$ODI_JAR /u01/$ODI_JAR2 /u01/fmw_122126_readme.htm /u01/oraInst.loc

WORKDIR $ORACLE_HOME

#
# Expose all Ports
#-----------------
EXPOSE $ODI_AGENT_PORT

#
# Define default command to start 
# -------------------------------
CMD ["/u01/oracle/container-scripts/CreateODIDomainandRunAgent.sh"]

