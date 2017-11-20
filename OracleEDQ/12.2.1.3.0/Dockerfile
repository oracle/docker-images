# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Enterprise Data Quality 12.2.1.3.0
#
# Base image of this dockerfile is Oracle Java 8 docker image.
#
# Pre-requisite to build oracle Oracle Enterprise Data Quality 12.2.1.3.0 image is to have
# Oracle Java 8 docker image
#
# To build Oracle Java 8 docker image, kindly refer below link
# https://github.com/oracle/docker-images/tree/master/OracleJava
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#  fmw_12.2.1.3.0_edq_generic.zip
#   Download the production distribution for Oracle Enterprise Data Quality from the Oracle Software Delivery Cloud
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Make sure that Oracle Java 8 image is available
# Run:
#      $ docker build -t oracle/edq:12.2.1.3.0 .
#
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.3

#
# Maintainer
# ----------
#MAINTAINER 

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV EDQ_ZIP=fmw_12.2.1.3.0_edq_Disk1_1of1.zip \
    EDQ_JAR=fmw_12.2.1.3.0_edq.jar \
    ORACLE_HOME=/u01/oracle \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/container-scripts \
    DOMAIN_NAME="edq_domain" \
    DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
    ADMIN_PORT=7001 \
    EDQ_PORT=8001

#
# Proxy needs to be set before running yum 
# ----------------------------------------
USER root
#RUN useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
RUN  mkdir -p /u01/oracle/container-scripts /u01/oracle/logs && \
     chmod a+xr /u01 

#
# Copy required files to build this image
# ---------------------------------------
COPY $EDQ_ZIP oraInst.loc /u01/
COPY container-scripts/* /u01/oracle/container-scripts/

RUN chown oracle:oracle -R /u01 && \
    chmod a+xr /u01/oracle/container-scripts/*.*

#
# Install as oracle user
# ----------------------
USER oracle
RUN cd /u01 && \
    $JAVA_HOME/bin/jar xf /u01/$EDQ_ZIP && \
    $JAVA_HOME/bin/java -jar /u01/$EDQ_JAR -silent -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Installation for Weblogic Server" && \
     rm /u01/$EDQ_JAR /u01/oraInst.loc

WORKDIR $ORACLE_HOME

#
# Expose all Ports
#-----------------
EXPOSE $ADMIN_PORT
EXPOSE $EDQ_PORT

#
# Define default command to start 
# -------------------------------
CMD ["/u01/oracle/container-scripts/CreateEDQDomainandStart.sh"]
