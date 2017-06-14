# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FMW Infrastructure 12.2.1.2
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.0_infrastructure_Disk1_1of1.zip
#     Download the Infrastructure installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html 
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -f Dockerfile -t oracle/fmw-infrastructure:12.2.1.2
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a FMW Infra Empty Domain.
#
# Pull base image
# From the Oracle Registry
# -------------------------
FROM oracle/serverjre:8

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>


# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    DOMAIN_NAME="${DOMAIN_NAME:-InfraDomain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-InfraDomain} \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts


    
# Setup filesystem and oracle user
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------  
RUN mkdir -p /u01 && \
    chmod a+xr /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    mkdir -p /u01/oracle/container-scripts

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG=fmw_12.2.1.2.0_infrastructure_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.2.0_infrastructure.jar

# Copy packages and scripts
# -------------
COPY $FMW_PKG install.file oraInst.loc /u01/ 
COPY container-scripts/* /u01/oracle/container-scripts/
RUN chown oracle:oracle -R /u01 && \
    chmod +x /u01/oracle/container-scripts/*.sh

# Install
# ------------------------------------------------------------

USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="WebLogic Server" && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/oraInst.loc /u01/install.file


WORKDIR ${ORACLE_HOME}

# Define default command to start script.
CMD ["/u01/oracle/container-scripts/createInfraDomainAndStartAdmin.sh"]
