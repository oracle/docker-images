# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle BPM 12.2.1.2 Quick Start
#
# Base image of this dockerfile is the server JRE 8 docker image.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.0_bpm_quickstart_generic.jar & 
#     fmw_12.2.1.2.0_bpm_quickstart_generic2.jar
# (2) Download from OTN
#     http://www.oracle.com/technetwork/middleware/soasuite/downloads/index.html
#     - Download Queue/Selected Item
#       - Oracle SOA Suite for Oracle Middleware (BPM, FMW, Service Oriented
#         Architecture
#       - Linux x86-64
#       - CONTINUE
#     - Download Queue/Select Release
#       - Oracle SOA Suite for Oracle Middleware 12.2.1.2.0 for Linux x86-64
#       - CONTINUE
#     - Accept Terms
#     - Download the following
#       - V779125-01_1of2.zip
#         Oracle Fusion Middleware 12c (12.2.1.2.0) Business Process Management
#         Quick Start for Developers
#       - V779125-01_2of2.zip
#         Oracle Fusion Middleware 12c (12.2.1.2.0) Business Process Management
#         Quick Start for Developers
#       - Unzip to get the 2 jars mentioned above
#
# Pull base image
# ---------------
FROM container-registry.oracle.com/java/serverjre:8u131
#
# Maintainer
# ----------
MAINTAINER Prashanth Nagaraja <prashanth.nagaraja@oracle.com>
#
#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV FMW_JAR1=fmw_12.2.1.2.0_bpm_quickstart_generic.jar \
    FMW_JAR2=fmw_12.2.1.2.0_bpm_quickstart_generic2.jar \
    ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin
    
# Install OL7 required packages. Refer FMW 12.2.1.2 System requirements 
# guide for complete list of packages
# Change the open file limits and kernel parameters that need changing
# Setup filesystem and oracle user
# Go to /u01 as user 'oracle' to proceed with SOA installation
#---------------------------------------------------------------
# Proxy needs to be set before running yum in /etc/yum.conf
# Useful developer tools in the docker Image
#
RUN yum install -y unzip tar hostname && \
    yum clean all && \
    mkdir -p /u01 /u01/oracle/dockertools && \
    chmod a+xr /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    chown oracle:oracle -R /u01
#
# Copy files and packages for install
# -----------------------------------
ADD $FMW_JAR1 $FMW_JAR2 /u01/
RUN cd /u01 && chmod 755 *.jar && chown oracle:oracle -R /u01
#
USER oracle
COPY *.response oraInst.loc /u01/
RUN cd /u01 && \
  $JAVA_HOME/bin/java -jar $FMW_JAR1 -silent -responseFile /u01/soabpm.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
  rm -f /u01/*.jar /u01/oraInst.loc /u01/*.response

#
# Copy Domain creation scripts
#
USER root
COPY container-scripts/* /u01/oracle/dockertools/
RUN chmod a+xr /u01/oracle/dockertools/*.*

#
# Define default command to start bash.
#
USER oracle
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
