# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle WebCenter Portal 12.2.1.4
#
# Base image of this dockerfile is Oracle FMW Infrastructure 12.2.1.4.0
# Pull base image from the Oracle Container Registry or Docker Store and tag the name as 'oracle/fmw-infrastructure:12.2.1.4.0'
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.4.0_wcportal.jar
#
# Download all dependent binaries from : http://changeiq.oraclecorp.com/fmw-stage/?release=FMW12.2.1.4.0
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/wcportal:12.2.1.4.0 .
#
# -------------------------------------------------------------
FROM oracle/fmw-infrastructure:12.2.1.4.0 as builder

LABEL "provider"="Oracle"                                          \
      "maintainer"="Anand Sirasagi <anand.sirasagi@oracle.com>"    \
      "issues"="https://github.com/oracle/docker-images/issues"

# -------------------------------------------------------------
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV FMW_PORTAL_JAR=fmw_12.2.1.4.0_wcportal.jar \
    ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts
# -------------------------------------------------------------
# Setup filesystem and oracle user
# Unzip WCPORTAL installer
# Go to /u01 as user 'oracle' to proceed with WCPORTAL installation
#
# Note : Proxy needs to be set before running yum in /etc/yum.conf
# -------------------------------------------------------------

RUN mkdir -p /u01 && \
    chmod a+xr /u01 && \
    mkdir -p /u01/oracle/container-scripts && \
    mkdir -p /u01/oracle/logs && \
    mkdir -p /u01/esHome/esNode

# copy container scripts
# -------------------------------------------------------------
COPY container-scripts/*.sh container-scripts/*.py /u01/oracle/container-scripts/
COPY $FMW_PORTAL_JAR install.file oraInst.loc /u01/

# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# -------------------------------------------------------------
RUN chown oracle:oracle -R /u01 && \
    chmod a+xr /u01/oracle/*.*

# Install as user
# -------------------------------------------------------------
USER oracle

# Install WebCenter Portal binary
# -------------------------------------------------------------
RUN $JAVA_HOME/bin/java -jar /u01/$FMW_PORTAL_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="WebCenter Portal" && \
rm /u01/$FMW_PORTAL_JAR /u01/oraInst.loc /u01/install.file /u01/oracle/oracle_common/lib/ons.jar /u01/oracle/oracle_common/modules/oracle.jdbc/simplefan.jar

#Rebuilding Base image
FROM oracle/fmw-infrastructure:12.2.1.4.0
#
# Install the required packages
# -----------------------------
USER root

ENV PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts

RUN  yum install -y sudo hostname zip unzip tar procps  &&\
     rm -rf /var/cache/yum

COPY --from=builder --chown=oracle:oracle /u01 /u01


# Expose all Ports
# -------------------------------------------------------------
EXPOSE $WCPORTAL_PORT $ADMIN_PORT

USER oracle
# Set work directory

# -------------------------------------------------------------
WORKDIR $ORACLE_HOME

# -------------------------------------------------------------
# Define default script
CMD ["/u01/oracle/container-scripts/configureOrStartAdminServer.sh"]