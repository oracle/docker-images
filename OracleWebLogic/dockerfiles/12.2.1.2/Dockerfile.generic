# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle WebLogic Server 12.2.1.2 Generic Distro
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.0_wls_Disk1_1of1.zip 
#     Download the Generic installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html 
#
# (2) server-jre-8uXX-linux-x64.tar.gz
#     Download from http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html 
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -f Dockerfile.generic -t oracle/weblogic:12.2.1.2-generic . 
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a WLS Empty Domain.
#
# Pull base image
# From the Oracle Registry
# -------------------------
FROM oracle/serverjre:8

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# WLS Configuration (editable during build time)
# ------------------------------
ARG ADMIN_PASSWORD


# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG=fmw_12.2.1.2.0_wls_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.2.0_wls.jar \
    SCRIPT_FILE=/u01/oracle/createAndStartEmptyDomain.sh \
    ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    DEBUG_FLAG=true \
    PRODUCTION_MODE=dev \
    DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-base_domain} \
    ADMIN_PORT="${ADMIN_PORT:-8001}" \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin

# Copy packages
# -------------
COPY $FMW_PKG install.file oraInst.loc /u01/
COPY container-scripts/createAndStartEmptyDomain.sh container-scripts/create-wls-domain.py /u01/oracle/

# Setup filesystem and oracle user
# Install and configure Oracle JDK
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------
RUN chmod a+xr /u01 && \
    chmod +xr $SCRIPT_FILE && \
    useradd -b /u01 -M -s /bin/bash oracle && \
    chown oracle:oracle -R /u01 && \
    echo oracle:oracle | chpasswd && \
    cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    su -c "$JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE=\"WebLogic Server\"" - oracle && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/oraInst.loc /u01/install.file

WORKDIR ${ORACLE_HOME}

# Define default command to start script. 
CMD ["/u01/oracle/createAndStartEmptyDomain.sh"]
