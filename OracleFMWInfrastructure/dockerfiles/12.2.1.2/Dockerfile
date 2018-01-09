#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FMW Infrastructure 12.2.1.2
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# The Oracle FMW Infrastructure image extends the Oracle WebLogic Infrastructure 12.2.1.2 image, you must first build the Oracle WebLogic Infrastructure image.
# Run: 
#      $ docker build -f Dockerfile -t oracle/fmw-infrastructure:12.2.1.2
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a FMW Infra Base Domain.
#
# From 
# -------------------------
FROM oracle/serverjre:8

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>


# Common environment variables required for this build 
# ----------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    SCRIPT_FILES=/u01/oracle/container-scripts/*.sh \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    DOMAIN_NAME="${DOMAIN_NAME:-InfraDomain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-InfraDomain} \
    VOLUME_DIR=/u01/oracle/user_projects \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts


#USER root    
# Setup subdirectory for FMW install package and container-scripts
# -----------------------------------------------------------------  
RUN mkdir -p /u01 && \ 
    chmod a+xr /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    mkdir -p /u01/oracle/container-scripts


# Copy packages and scripts
# -------------
COPY container-scripts/* /u01/oracle/container-scripts/

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG=fmw_12.2.1.2.0_infrastructure_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.2.0_infrastructure.jar

# Copy packages
# -------------
COPY $FMW_PKG install.file oraInst.loc /u01/
RUN chown oracle:oracle -R /u01 && \
    chmod +xr $SCRIPT_FILES && \
    yum install -y libaio && \
    rm -rf /var/cache/yum && \
    mkdir -p $VOLUME_DIR && \
    chown -R oracle:oracle $VOLUME_DIR

VOLUME $VOLUME_DIR


# Install 
# ------------------------------------------------------------
USER oracle
RUN  cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="WebLogic Server" && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/oraInst.loc /u01/install.file

WORKDIR ${ORACLE_HOME}

# Define default command to start script.
CMD ["/u01/oracle/container-scripts/createOrStartInfraDomain.sh"]
